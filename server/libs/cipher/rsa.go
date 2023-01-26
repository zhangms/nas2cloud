package cipher

import (
	"bytes"
	"crypto/rand"
	"crypto/rsa"
	"crypto/x509"
	"encoding/hex"
	"encoding/pem"
)

func GenerateRsaKeyPem(bits int) (privateKeyPem, publicKeyPem string, err error) {
	privateKey, err := rsa.GenerateKey(rand.Reader, bits)
	if err != nil {
		return "", "", err
	}
	//保存私钥
	privateKeyBytes := x509.MarshalPKCS1PrivateKey(privateKey)
	pri := &bytes.Buffer{}
	pem.Encode(pri, &pem.Block{
		Type:  "RSA PRIVATE KEY",
		Bytes: privateKeyBytes,
	})
	//保存公钥
	publicKeyBytes := x509.MarshalPKCS1PublicKey(&privateKey.PublicKey)
	pub := &bytes.Buffer{}
	pem.Encode(pub, &pem.Block{
		Type:  "RSA PUBLIC KEY",
		Bytes: publicKeyBytes,
	})
	return pri.String(), pub.String(), nil
}

func RsaEncrypt(publicKeyPem string, data []byte) ([]byte, error) {
	p, _ := pem.Decode([]byte(publicKeyPem))
	publicKey, err := x509.ParsePKCS1PublicKey(p.Bytes)
	if err != nil {
		return nil, err
	}
	return rsa.EncryptPKCS1v15(rand.Reader, publicKey, data)
}

func RsaEncryptToString(publicKeyPem string, data []byte) (string, error) {
	chipertext, err := RsaEncrypt(publicKeyPem, data)
	if err != nil {
		return "", err
	}
	return hex.EncodeToString(chipertext), nil
}

func RsaDecrypt(privateKeyPem string, data []byte) ([]byte, error) {
	p, _ := pem.Decode([]byte(privateKeyPem))
	privateKey, err := x509.ParsePKCS1PrivateKey(p.Bytes)
	if err != nil {
		return nil, err
	}
	return rsa.DecryptPKCS1v15(rand.Reader, privateKey, data)
}
