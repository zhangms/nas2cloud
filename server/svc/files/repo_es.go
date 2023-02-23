package files

import (
	_ "embed"
	"encoding/base64"
	"encoding/json"
	"nas2cloud/libs/logger"
	"nas2cloud/libs/vfs"
	"nas2cloud/libs/vfs/vpath"
	"nas2cloud/svc/es"
)

//go:embed repo_es_files_index_specific.json
var esFilesIndexSpecific string

const esFileIndex = "files"

type ObjectInfoDoc struct {
	*vfs.ObjectInfo
	Parent string
}

func (o *ObjectInfoDoc) Id() string {
	return docId(o.Path)
}

func docId(id string) string {
	return base64.RawURLEncoding.EncodeToString([]byte(id))
}

func NewObjectInfoDoc(info *vfs.ObjectInfo) *ObjectInfoDoc {
	return &ObjectInfoDoc{
		ObjectInfo: info,
		Parent:     vpath.Dir(info.Path),
	}
}

type repositoryEs struct {
	env string
}

func (r *repositoryEs) namespace(index string) string {
	return r.env + "_" + index
}

func (r *repositoryEs) createIndex() error {
	index := r.namespace(esFileIndex)
	exists, _ := es.IndexExists(index)
	if !exists {
		_ = es.CreateIndex(index, nil)
	}
	if err := es.UpdateIndexMapping(index, []byte(esFilesIndexSpecific)); err != nil {
		logger.Error("update index mapping error", index, err)
		return err
	}
	return nil
}

func (r *repositoryEs) exists(path string) (bool, error) {
	index := r.namespace(esFileIndex)
	return es.Exists(index, docId(path))
}

func (r *repositoryEs) get(path string) (*vfs.ObjectInfo, error) {
	type doc struct {
		Source *ObjectInfoDoc `json:"_source"`
	}
	index := r.namespace(esFileIndex)
	d := &doc{}
	if err := es.Get(index, docId(path), d); err != nil {
		return nil, err
	}
	if d.Source == nil {
		return nil, nil
	}
	return d.Source.ObjectInfo, nil
}

func (r *repositoryEs) saveIfAbsent(item *vfs.ObjectInfo) error {
	doc := NewObjectInfoDoc(item)
	index := r.namespace(esFileIndex)
	exists, err := es.Exists(index, doc.Id())
	if err != nil {
		return err
	}
	if exists {
		return nil
	}
	data, err := json.Marshal(doc)
	if err != nil {
		return err
	}
	return es.Create(index, doc.Id(), data)
}

func (r *repositoryEs) save(item *vfs.ObjectInfo) error {
	doc := NewObjectInfoDoc(item)
	data, err := json.Marshal(doc)
	if err != nil {
		return err
	}
	index := r.namespace(esFileIndex)
	return es.CreateOrUpdate(index, doc.Id(), data)
}

func (r *repositoryEs) delete(path string) error {
	index := r.namespace(esFileIndex)
	_, err := es.Delete(index, docId(path))
	return err
}

func (r *repositoryEs) find(path string, orderBy string, start int64, stop int64) ([]*vfs.ObjectInfo, int64, error) {
	//TODO implement me
	panic("implement me")
}

func (r *repositoryEs) updateSize(file string, size int64) error {
	index := r.namespace(esFileIndex)
	mp := map[string]any{
		"Size": size,
	}
	return es.Update(index, docId(file), mp)
}

func (r *repositoryEs) updatePreview(file string, preview string) error {
	index := r.namespace(esFileIndex)
	mp := map[string]any{
		"Preview": preview,
	}
	return es.Update(index, docId(file), mp)
}

func (r *repositoryEs) updateDirModTimeByChildren(path string) error {
	info, _ := r.get(path)
	if info == nil && info.Type != vfs.ObjectTypeDir {
		return nil
	}

	//index := r.namespace(esFileIndex)
	//mp := map[string]any{
	//	"Preview": preview,
	//}
	//return es.Update(index, docId(file), mp)
	return nil
}
