package sign

import (
	"errors"
	"nas2cloud/libs/cipher"
	"nas2cloud/svc/cache"
	"sync"
)

type SignSvc struct {
}

var signSvc = &SignSvc{}

func Sign() *SignSvc {
	return signSvc
}

const cacheKeyRsaPublicPem = "rsa.pub.pem"
const cacheKeyRsaPrivatePem = "rsa.pem"

var mutex = &sync.Mutex{}

func (d *SignSvc) tryGenerateKey() error {
	count, err := cache.Exists(cacheKeyRsaPublicPem, cacheKeyRsaPrivatePem)
	if err != nil {
		return err
	}
	if count == 2 {
		return nil
	}
	mutex.Lock()
	defer mutex.Unlock()
	pri, pub, err := cipher.GenerateRsaKeyPem(2048)
	if err != nil {
		return err
	}
	_, err = cache.Set(cacheKeyRsaPrivatePem, pri)
	if err != nil {
		return err
	}
	_, err = cache.Set(cacheKeyRsaPublicPem, pub)
	return err
}

func (d *SignSvc) GetPublicKey() (string, error) {
	err := d.tryGenerateKey()
	if err != nil {
		return "", err
	}
	value, err := cache.Get(cacheKeyRsaPublicPem)
	if err != nil {
		return "", err
	}
	return value, err
}

func (d *SignSvc) DecryptToString(chipertext []byte) (string, error) {
	value, err := cache.Get(cacheKeyRsaPrivatePem)
	if err != nil {
		return "", err
	}
	if len(value) == 0 {
		return "", errors.New("private key not exists")
	}
	data, err := cipher.RsaDecrypt(value, chipertext)
	if err != nil {
		return "", err
	}
	return string(data), nil
}
