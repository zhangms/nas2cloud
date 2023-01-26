package sign

import (
	"encoding/json"
	"errors"
	"nas2cloud/libs/cipher"
	"nas2cloud/libs/errs"
	"nas2cloud/svc/cache"
)

type SignSvc struct {
}

var signSvc = &SignSvc{}

func Sign() *SignSvc {
	return signSvc
}

const keyRSAPem = "rsa.pem"

func (d *SignSvc) cacheKey(flag string) string {
	return keyRSAPem + "." + flag
}

func (d *SignSvc) tryGenerateRSAKey(flag string) error {
	key := d.cacheKey(flag)
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

func (d *SignSvc) GetPublicKey(flag string) (string, error) {
	_, pub, err := d.getRSAKey(flag)
	if err != nil {
		return "", errs.Wrap(err, "GetPublicKey")
	}
	return pub, err
}

func (d *SignSvc) getRSAKey(flag string) (rsaPrivateKey string, rsaPublicKey string, err error) {
	err = d.tryGenerateRSAKey(flag)
	if err != nil {
		return "", "", err
	}
	key := d.cacheKey(flag)
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

func (d *SignSvc) DecryptToString(flag string, chipertext []byte) (string, error) {
	pri, _, err := d.getRSAKey(flag)
	if err != nil {
		return "", err
	}
	data, err := cipher.RsaDecrypt(pri, chipertext)
	if err != nil {
		return "", err
	}
	return string(data), nil
}
