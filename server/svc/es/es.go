package es

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"github.com/elastic/go-elasticsearch/v8"
	"github.com/elastic/go-elasticsearch/v8/esapi"
	"github.com/elastic/go-elasticsearch/v8/esutil"
	"io"
	"nas2cloud/res"
)

type config struct {
	Address  []string `json:"address"`
	Username string   `json:"username"`
	Password string   `json:"password"`
}

var client *elasticsearch.Client

func DoInit(env string) {
	data, err := res.ReadByEnv(env, "es.json")
	if err != nil {
		panic(err)
	}
	conf := &config{}
	if err = json.Unmarshal(data, conf); err != nil {
		panic(err)
	}
	c, err := elasticsearch.NewClient(elasticsearch.Config{
		Addresses: conf.Address,
		Username:  conf.Username,
		Password:  conf.Password,
	})
	if err != nil {
		panic(err)
	}
	client = c
}

//func Client() *elasticsearch.Client {
//	return client
//}

func IndexExists(index string) (bool, error) {
	req := esapi.IndicesExistsRequest{
		Index: []string{index},
	}
	resp, err := req.Do(context.Background(), client)
	if err != nil {
		return false, err
	}
	defer closeResponse(resp)
	if resp.IsError() {
		return false, errors.New(resp.String())
	}
	return true, nil
}

func CreateIndex(index string, indexSetting []byte) error {
	req := esapi.IndicesCreateRequest{
		Index: index,
		Body:  bytes.NewReader(indexSetting),
	}
	resp, err := req.Do(context.Background(), client)
	if err != nil {
		return err
	}
	defer closeResponse(resp)
	if resp.IsError() {
		return errors.New(resp.String())
	}
	return nil
}

func DeleteIndex(index string) error {
	req := esapi.IndicesDeleteRequest{
		Index: []string{index},
	}
	resp, err := req.Do(context.Background(), client)
	if err != nil {
		return err
	}
	defer closeResponse(resp)
	if resp.IsError() {
		return errors.New(resp.String())
	}
	return nil
}

func UpdateIndexMapping(index string, mapping []byte) error {
	req := esapi.IndicesPutMappingRequest{
		Index: []string{index},
		Body:  bytes.NewBuffer(mapping),
	}
	resp, err := req.Do(context.Background(), client)
	if err != nil {
		return err
	}
	defer closeResponse(resp)
	if resp.IsError() {
		return errors.New(resp.String())
	}
	return nil
}

func CreateOrUpdate(index string, id string, doc []byte) error {
	req := esapi.IndexRequest{
		Index:      index,
		DocumentID: id,
		Body:       bytes.NewReader(doc),
	}
	resp, err := req.Do(context.Background(), client)
	if err != nil {
		return err
	}
	defer closeResponse(resp)
	if resp.IsError() {
		return errors.New(resp.String())
	}
	return nil
}

func Create(index string, id string, doc []byte) error {
	req := esapi.CreateRequest{
		Index:      index,
		DocumentID: id,
		Body:       bytes.NewReader(doc),
	}
	resp, err := req.Do(context.Background(), client)
	if err != nil {
		return err
	}
	defer closeResponse(resp)
	if resp.IsError() {
		return errors.New(resp.String())
	}
	return nil
}

func Exists(index string, id string) (bool, error) {
	req := esapi.ExistsRequest{
		Index:      index,
		DocumentID: id,
	}
	resp, err := req.Do(context.Background(), client)
	if err != nil {
		return false, err
	}
	defer closeResponse(resp)
	if resp.IsError() {
		return false, nil
	}
	return true, nil
}

func Get(index string, id string, dest any) error {
	req := esapi.GetRequest{
		Index:      index,
		DocumentID: id,
	}
	resp, err := req.Do(context.Background(), client)
	if err != nil {
		return err
	}
	defer closeResponse(resp)
	if resp.IsError() {
		return nil
	}
	data, err := io.ReadAll(resp.Body)
	if err != nil {
		return err
	}
	return json.Unmarshal(data, dest)
}

func Delete(index string, id string) (int, error) {
	req := esapi.DeleteRequest{
		Index:      index,
		DocumentID: id,
	}
	resp, err := req.Do(context.Background(), client)
	if err != nil {
		return 0, err
	}
	defer closeResponse(resp)
	if resp.IsError() {
		return 0, nil
	}
	return 1, nil
}

func Update(index string, id string, field map[string]any) error {
	if field == nil || len(field) == 0 {
		return nil
	}
	body := make(map[string]any)
	body["doc"] = field
	req := esapi.UpdateRequest{
		Index:      index,
		DocumentID: id,
		Body:       esutil.NewJSONReader(body),
	}
	resp, err := req.Do(context.Background(), client)
	if err != nil {
		return err
	}
	defer closeResponse(resp)
	if resp.IsError() {
		return errors.New(resp.String())
	}
	return nil
}

func SearchPage(index string) {
}

func closeResponse(resp *esapi.Response) {
	_ = resp.Body.Close()
}
