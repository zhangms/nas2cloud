package files

import (
	_ "embed"
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

func NewObjectInfoDoc(info *vfs.ObjectInfo) *ObjectInfoDoc {
	return &ObjectInfoDoc{
		ObjectInfo: info,
		Parent:     vpath.Dir(info.Path),
	}
}

type repositoryEs struct {
}

func (r *repositoryEs) createIndex() error {
	exists, _ := es.IndexExists(esFileIndex)
	if !exists {
		_ = es.CreateIndex(esFileIndex, nil)
	}
	if err := es.UpdateIndexMapping(esFileIndex, []byte(esFilesIndexSpecific)); err != nil {
		logger.Error("update index mapping error", esFileIndex, err)
		return err
	}
	return nil
}

func (r *repositoryEs) exists(path string) (bool, error) {
	//TODO implement me
	panic("implement me")
}

func (r *repositoryEs) get(path string) (*vfs.ObjectInfo, error) {
	//TODO implement me
	panic("implement me")
}

func (r *repositoryEs) saveIfAbsent(item *vfs.ObjectInfo) error {
	//TODO implement me
	panic("implement me")
}

func (r *repositoryEs) save(item *vfs.ObjectInfo) error {

	//fmt.Println(objectInfoDocMapping)
	//
	//doc := NewObjectInfoDoc(item)
	//data, _ := json.Marshal(doc)
	//req := esapi.CreateRequest{
	//	Index: esFileIndex,
	//	Body:  bytes.NewReader(data),
	//
	//}
	//esapi.IndexRequest{
	//	Index:
	//}

	return nil
}

func (r *repositoryEs) delete(path string) error {
	//TODO implement me
	panic("implement me")
}

func (r *repositoryEs) find(path string, orderBy string, start int64, stop int64) ([]*vfs.ObjectInfo, int64, error) {
	//TODO implement me
	panic("implement me")
}

func (r *repositoryEs) updateSize(file string, size int64) error {
	//TODO implement me
	panic("implement me")
}

func (r *repositoryEs) updatePreview(file string, preview string) {
	//TODO implement me
	panic("implement me")
}

func (r *repositoryEs) updateModTime(path string) {
	//TODO implement me
	panic("implement me")
}
