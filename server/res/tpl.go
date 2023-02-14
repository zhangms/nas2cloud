package res

import (
	"bytes"
	htmlTemplate "html/template"
	"io"
	textTemplate "text/template"
)

type tpl interface {
	execute(wr io.Writer, params any) error
}

type tplHtml struct {
	html *htmlTemplate.Template
}

func (t *tplHtml) execute(wr io.Writer, params any) error {
	return t.html.Execute(wr, params)
}

type tplText struct {
	text *textTemplate.Template
}

func (t *tplText) execute(wr io.Writer, params any) error {
	return t.text.Execute(wr, params)
}

func parse(tplType string, name string, content string) (tpl, error) {
	if tplType == "html" {
		t, err := htmlTemplate.New(name).Parse(content)
		if err != nil {
			return nil, err
		}
		return &tplHtml{
			html: t,
		}, nil
	} else {
		t, err := textTemplate.New(name).Parse(content)
		if err != nil {
			return nil, err
		}
		return &tplText{
			text: t,
		}, nil
	}
}

func template(tplType string, name string, params any) ([]byte, error) {
	data, err := Read("tpl/" + name)
	if err != nil {
		return nil, err
	}
	if params == nil {
		return data, nil
	}
	t, err := parse(tplType, name, string(data))
	if err != nil {
		return nil, err
	}
	var buffer bytes.Buffer
	err = t.execute(&buffer, params)
	if err != nil {
		return nil, err
	}
	return buffer.Bytes(), nil
}

func ParseHtml(name string, params any) ([]byte, error) {
	return template("html", name, params)
}

func ParseText(name string, params any) ([]byte, error) {
	return template("text", name, params)
}
