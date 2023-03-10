package sign

import (
	"encoding/json"
	"errors"
	"nas2cloud/libs/cipher"
	"nas2cloud/libs/logger"
	"nas2cloud/svc/cache"
)

const keyRSAPem = "rsa.pem"

func cacheKey(flag string) string {
	return keyRSAPem + "." + flag
}

func tryGenerateRSAKey(flag string) error {
	key := cacheKey(flag)
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

func GetPublicKey(flag string) (string, error) {
	_, pub, err := getRSAKey(flag)
	return pub, err
}

func getRSAKey(flag string) (rsaPrivateKey string, rsaPublicKey string, err error) {
	pri, pub, err := getRSAKeyImpl(flag)
	logger.PrintIfError(err, "getRSAKey", flag)
	return pri, pub, err
}

func getRSAKeyImpl(flag string) (rsaPrivateKey string, rsaPublicKey string, err error) {
	err = tryGenerateRSAKey(flag)
	if err != nil {
		return "", "", err
	}
	key := cacheKey(flag)
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

func DecryptToString(flag string, chipertext []byte) (string, error) {
	pri, _, err := getRSAKey(flag)
	if err != nil {
		return "", err
	}
	data, err := cipher.RsaDecrypt(pri, chipertext)
	if err != nil {
		return "", err
	}
	return string(data), nil
}
