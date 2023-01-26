package sign

import (
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
	pri, pub, err := cipher.GenerateRsaKeyPem(1024)
	if err != nil {
		return err
	}
	cache.Set(cacheKeyRsaPrivatePem, pri)
	cache.Set(cacheKeyRsaPublicPem, pub)
	return nil
}

func (d *SignSvc) GetPublicKey() (string, error) {
	d.tryGenerateKey()
	value, err := cache.Get(cacheKeyRsaPublicPem)
	if err != nil {
		return "", err
	}
	return value, err
}
