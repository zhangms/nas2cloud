package es

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"github.com/elastic/go-elasticsearch/v8"
	"github.com/elastic/go-elasticsearch/v8/esapi"
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

func IndexExists(indexName string) (bool, error) {
	req := esapi.IndicesExistsRequest{
		Index: []string{indexName},
	}
	resp, err := req.Do(context.Background(), client)
	if err != nil {
		return false, err
	}
	defer closeBody(resp)
	if resp.IsError() {
		return false, errors.New(resp.String())
	}
	return true, nil
}

func CreateIndex(indexName string, indexSetting []byte) error {
	req := esapi.IndicesCreateRequest{
		Index: indexName,
		Body:  bytes.NewReader(indexSetting),
	}
	resp, err := req.Do(context.Background(), client)
	if err != nil {
		return err
	}
	defer closeBody(resp)
	if resp.IsError() {
		return errors.New(resp.String())
	}
	return nil
}

func DeleteIndex(indexName string) error {
	req := esapi.IndicesDeleteRequest{
		Index: []string{indexName},
	}
	resp, err := req.Do(context.Background(), client)
	if err != nil {
		return err
	}
	defer closeBody(resp)
	if resp.IsError() {
		return errors.New(resp.String())
	}
	return nil
}

func UpdateIndexMapping(indexName string, mapping []byte) error {
	req := esapi.IndicesPutMappingRequest{
		Index: []string{indexName},
		Body:  bytes.NewBuffer(mapping),
	}
	resp, err := req.Do(context.Background(), client)
	if err != nil {
		return err
	}
	defer closeBody(resp)
	if resp.IsError() {
		return errors.New(resp.String())
	}
	return nil
}

func closeBody(resp *esapi.Response) {
	_ = resp.Body.Close()
}
