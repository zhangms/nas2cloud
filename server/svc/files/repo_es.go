package files

import (
	_ "embed"
	"encoding/base64"
	"encoding/json"
	"nas2cloud/libs"
	"nas2cloud/libs/logger"
	"nas2cloud/libs/vfs"
	"nas2cloud/libs/vfs/vpath"
	"nas2cloud/res"
	"nas2cloud/svc/es"
	"strings"
)

//go:embed es-mapper/files_index_mapping.json
var esFilesIndexMapping string

//go:embed es-mapper/files_index_query_by_parent.json.tpl
var esFilesIndexQueryByParent string

const esFileIndex = "files"

type ObjectInfoDoc struct {
	*vfs.ObjectInfo
	Parent string
	Bucket string
}

func (o *ObjectInfoDoc) Id() string {
	return docId(o.Path)
}

func docId(id string) string {
	return base64.RawURLEncoding.EncodeToString([]byte(id))
}

func NewObjectInfoDoc(info *vfs.ObjectInfo) *ObjectInfoDoc {
	bucket, _ := vpath.BucketFile(info.Path)
	return &ObjectInfoDoc{
		ObjectInfo: info,
		Parent:     vpath.Dir(info.Path),
		Bucket:     bucket,
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
	if err := es.UpdateIndexMapping(index, []byte(esFilesIndexMapping)); err != nil {
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
	if er := es.Create(index, doc.Id(), data); er != nil {
		return er
	}
	logger.Info("create file es", index, item.Path)
	return nil
}

func (r *repositoryEs) save(item *vfs.ObjectInfo) error {
	doc := NewObjectInfoDoc(item)
	data, err := json.Marshal(doc)
	if err != nil {
		return err
	}
	index := r.namespace(esFileIndex)
	if er := es.CreateOrUpdate(index, doc.Id(), data); er != nil {
		return er
	}
	logger.Info("save file es", index, item.Path)
	return nil
}

func (r *repositoryEs) delete(path string) error {
	index := r.namespace(esFileIndex)
	_, err := es.Delete(index, docId(path))
	return err
}

func (r *repositoryEs) walk(path string, orderBy string, start int64, stop int64) ([]*vfs.ObjectInfo, int64, error) {
	type params struct {
		Path          string
		From          int64
		Size          int64
		OrderByField  string
		OrderByDirect string
	}
	orderByField, orderByDirect := r.parseOrderBy(orderBy)
	param := &params{
		Path:          path,
		From:          start,
		Size:          stop - start,
		OrderByField:  orderByField,
		OrderByDirect: orderByDirect,
	}
	dsl, err := res.ParseText("esFilesIndexQueryByParent", esFilesIndexQueryByParent, param)
	if err != nil {
		return nil, 0, err
	}
	searchResult := &es.SearchResult[*ObjectInfoDoc]{}
	if err = es.Search(r.namespace(esFileIndex), dsl, searchResult); err != nil {
		return nil, 0, err
	}
	ret := make([]*vfs.ObjectInfo, 0)
	for _, doc := range searchResult.Hits.Hits {
		ret = append(ret, doc.Source.ObjectInfo)
	}
	return ret, searchResult.Hits.Total.Value, nil
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
	if info == nil || info.Type != vfs.ObjectTypeDir {
		return nil
	}
	items, _, err := r.walk(path, "modTime_desc", 0, 2)
	if err != nil {
		return err
	}
	if len(items) == 0 {
		return nil
	}
	itm := items[0]
	index := r.namespace(esFileIndex)
	mp := map[string]any{
		"ModTime": itm.ModTime,
	}
	return es.Update(index, docId(path), mp)
}

func (r *repositoryEs) parseOrderBy(orderBy string) (orderByField, orderByDirect string) {
	arr := strings.Split(orderBy, "_")
	orderByDirect = libs.IF(len(arr) > 1, func() any {
		return arr[1]
	}, func() any {
		return "asc"
	}).(string)
	field := arr[0]
	switch field {
	case "fileName":
		orderByField = "Name"
	case "size":
		orderByField = "Size"
	case "modTime":
		orderByField = "ModTime"
	case "creTime":
		orderByField = "CreTime"
	default:
		orderByField = "Name"
	}
	return
}
