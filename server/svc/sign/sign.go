package sign

import (
	"encoding/json"
	"errors"
	"nas2cloud/libs/cipher"
	"nas2cloud/libs/logger"
	"nas2cloud/svc/cache"
)

type Svc struct {
}

var signSvc = &Svc{}

func Instance() *Svc {
	return signSvc
}

const keyRSAPem = "rsa.pem"

func (ss *Svc) cacheKey(flag string) string {
	return keyRSAPem + "." + flag
}

func (ss *Svc) tryGenerateRSAKey(flag string) error {
	key := ss.cacheKey(flag)
	count, err := cache.Exists(key)
	if err != nil {
		return err
	}
	if count == 2 {
		return nil
	}
	pri, pub, err := cipher.GenerateRsaKeyPem(2048)
	if err != nil {
		return err
	}
	data := map[string]string{
		"pri": pri,
		"pub": pub,
	}
	str, _ := json.Marshal(data)
	_, err = cache.SetNX(key, string(str))
	return err
}

func (ss *Svc) GetPublicKey(flag string) (string, error) {
	_, pub, err := ss.getRSAKey(flag)
	return pub, err
}

func (ss *Svc) getRSAKey(flag string) (rsaPrivateKey string, rsaPublicKey string, err error) {
	pri, pub, err := ss.getRSAKeyImpl(flag)
	logger.PrintIfError(err, "getRSAKey", flag)
	return pri, pub, err
}

func (ss *Svc) getRSAKeyImpl(flag string) (rsaPrivateKey string, rsaPublicKey string, err error) {
	err = ss.tryGenerateRSAKey(flag)
	if err != nil {
		return "", "", err
	}
	key := ss.cacheKey(flag)
	value, err := cache.Get(key)
	if err != nil {
		return "", "", err
	}
	if len(value) == 0 {
		return "", "", errors.New("rsa key not exists")
	}
	mp := make(map[string]string)
	err = json.Unmarshal([]byte(value), &mp)
	if err != nil {
		return "", "", err
	}
	return mp["pri"], mp["pub"], nil
}

func (ss *Svc) DecryptToString(flag string, chipertext []byte) (string, error) {
	pri, _, err := ss.getRSAKey(flag)
	if err != nil {
		return "", err
	}
	data, err := cipher.RsaDecrypt(pri, chipertext)
	if err != nil {
		return "", err
	}
	return string(data), nil
}
