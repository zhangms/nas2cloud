package json2dart

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"reflect"
	"sort"
	"strings"
)

func Exec(input, output, className string) error {
	file, err := os.Open(input)
	if err != nil {
		return err
	}
	defer file.Close()
	data, err := io.ReadAll(file)
	if err != nil {
		return err
	}
	mp := make(map[string]any)
	if err = json.Unmarshal(data, &mp); err != nil {
		return err
	}
	classes := make([]string, 0)
	genDartClass(className, mp, &classes)

	for _, class := range classes {
		fmt.Println(class)
	}

	content := make([]string, 0)
	content = append(content, "import 'dart:convert';")
	content = append(content, classes...)
	dartName := filepath.Base(input)
	dartName = dartName[0 : len(dartName)-len(filepath.Ext(dartName))]
	outputFile := filepath.Join(output, dartName+".dart")
	return os.WriteFile(outputFile, []byte(strings.Join(content, "\n\n")), os.ModePerm)
}

const intent = 2

func genDartClass(className string, mp map[string]any, classes *[]string) {
	keys := make([]string, 0, len(mp))
	for key := range mp {
		keys = append(keys, key)
	}
	sort.Slice(keys, func(i, j int) bool {
		return strings.Compare(keys[i], keys[j]) < 0
	})
	fields := getFields(className, keys, mp)

	bodyLines := make([]*codeLine, 0)
	bodyLines = append(bodyLines, genFieldsPart(fields)...)
	bodyLines = append(bodyLines, emptyLine())
	bodyLines = append(bodyLines, genConstructor(className, fields)...)
	bodyLines = append(bodyLines, emptyLine())
	bodyLines = append(bodyLines, genFromMap(className, fields)...)
	bodyLines = append(bodyLines, emptyLine())
	bodyLines = append(bodyLines, genToMap(fields)...)
	bodyLines = append(bodyLines, emptyLine())
	bodyLines = append(bodyLines, genFromJson(className, fields)...)
	bodyLines = append(bodyLines, emptyLine())
	bodyLines = append(bodyLines, genToJson()...)
	bodyLines = append(bodyLines, emptyLine())
	bodyLines = append(bodyLines, genToString()...)
	bodyLines = append(bodyLines, emptyLine())
	bodyLines = append(bodyLines, genCopyWith(className, fields)...)

	classLines := make([]*codeLine, 0)
	classLines = append(classLines, line(fmt.Sprintf("class %s {", className)))
	for _, bodyLine := range bodyLines {
		classLines = append(classLines, bodyLine.addIndent(intent))
	}
	classLines = append(classLines, line("}")) //end class
	ret := make([]string, 0)
	for _, line := range classLines {
		ret = append(ret, line.String())
	}
	*classes = append(*classes, strings.Join(ret, "\n"))
	for _, field := range fields {
		if len(field.innerType) == 0 {
			continue
		}
		if field.fieldType == field.innerType {
			genDartClass(field.innerType, field.template.(map[string]any), classes)
		} else {
			value := reflect.ValueOf(field.template).Index(0).Interface()
			valueMp := value.(map[string]any)
			genDartClass(field.innerType, valueMp, classes)
		}
	}
}

func genCopyWith(className string, fields []*jsonField) []*codeLine {
	ret := make([]*codeLine, 0)
	ret = append(ret, line(fmt.Sprintf("%s copyWith({", className)))
	for _, field := range fields {
		ret = append(ret, indentLine(fmt.Sprintf("%s %s,", field.fieldType+"?", field.name), intent))
	}
	ret = append(ret, line("}) {"))
	ret = append(ret, indentLine(fmt.Sprintf("return %s(", className), intent))
	for _, field := range fields {
		ret = append(ret, indentLine(fmt.Sprintf("%s: %s ?? this.%s,", field.name, field.name, field.name), intent*2))
	}
	ret = append(ret, indentLine(");", intent))
	ret = append(ret, line("}"))
	return ret
}

func genToString() []*codeLine {
	ret := make([]*codeLine, 0)
	ret = append(ret, line("@override"))
	ret = append(ret, line("String toString() => toJson();"))
	return ret
}

func genToJson() []*codeLine {
	ret := make([]*codeLine, 0)
	ret = append(ret, line("String toJson() => json.encode(toMap());"))
	return ret
}

func genFromJson(className string, fields []*jsonField) []*codeLine {
	ret := make([]*codeLine, 0)
	ret = append(ret, line(fmt.Sprintf("factory %s.fromJson(String data) {", className)))
	ret = append(ret, indentLine(fmt.Sprintf("return %s.fromMap(json.decode(data) as Map<String, dynamic>);", className), intent))
	ret = append(ret, line("}"))
	return ret
}

func genToMap(fields []*jsonField) []*codeLine {
	ret := make([]*codeLine, 0)
	ret = append(ret, line("Map<String, dynamic> toMap() => {"))
	for _, field := range fields {
		if field.isBuiltinType() {
			ret = append(ret, indentLine(fmt.Sprintf("'%s': %s,", field.name, field.name), intent*2))
		}
		if field.isObjectType() && field.required {
			ret = append(ret, indentLine(fmt.Sprintf("'%s': %s.toMap(),", field.name, field.name), intent*2))
		}
		if field.isObjectType() && !field.required {
			ret = append(ret, indentLine(fmt.Sprintf("'%s': %s?.toMap(),", field.name, field.name), intent*2))
		}
		if field.isListType() && field.required {
			ret = append(ret, indentLine(fmt.Sprintf("'%s': %s.map((e) => e.toMap()).toList(),", field.name, field.name), intent*2))
		}
		if field.isListType() && !field.required {
			ret = append(ret, indentLine(fmt.Sprintf("'%s': %s?.map((e) => e.toMap()).toList(),", field.name, field.name), intent*2))
		}
	}
	ret = append(ret, line("};"))
	return ret
}

func genFromMap(className string, fields []*jsonField) []*codeLine {
	ret := make([]*codeLine, 0)
	ret = append(ret, line(fmt.Sprintf("factory %s.fromMap(Map<String, dynamic> data) {", className)))
	ret = append(ret, indentLine(fmt.Sprintf("return %s(", className), intent))

	for _, field := range fields {
		if field.isBuiltinType() {
			ret = append(ret, indentLine(fmt.Sprintf("%s: data['%s'] as %s,", field.name, field.name, field.dartTypeName()), intent*2))
		}
		if field.isObjectType() && field.required {
			ret = append(ret, indentLine(fmt.Sprintf("%s: %s.fromMap(data['%s'] as Map<String, dynamic>),", field.name, field.innerType, field.name), intent*2))
		}
		if field.isObjectType() && !field.required {
			ret = append(ret, indentLine(fmt.Sprintf("%s: data['%s']==null ? null : %s.fromMap(data['%s'] as Map<String, dynamic>),", field.name, field.name, field.innerType, field.name), intent*2))
		}
		if field.isListType() && field.required {
			ret = append(ret, indentLine(fmt.Sprintf("%s: (data['%s'] as List<dynamic>).map((e) => %s.fromMap(e as Map<String, dynamic>)).toList(),", field.name, field.name, field.innerType), intent*2))
		}
		if field.isListType() && !field.required {
			ret = append(ret, indentLine(fmt.Sprintf("%s: (data['%s'] as List<dynamic>?)?.map((e) => %s.fromMap(e as Map<String, dynamic>)).toList(),", field.name, field.name, field.innerType), intent*2))
		}
	}
	ret = append(ret, indentLine(");", intent))
	ret = append(ret, line("}"))
	return ret
}

func genConstructor(className string, fields []*jsonField) []*codeLine {
	ret := make([]*codeLine, 0)
	ret = append(ret, line(className+"({"))
	for _, field := range fields {
		required := ""
		if field.required {
			required = "required "
		}
		ret = append(ret, indentLine(fmt.Sprintf("%sthis.%s,", required, field.name), intent))
	}
	ret = append(ret, line("});"))
	return ret
}

func genFieldsPart(fields []*jsonField) []*codeLine {
	ret := make([]*codeLine, 0)
	for _, field := range fields {
		ret = append(ret, line(fmt.Sprintf("%s %s;", field.dartTypeName(), field.name)))
	}
	return ret
}

func getFields(className string, keys []string, mp map[string]any) []*jsonField {
	ret := make([]*jsonField, 0)
	for _, key := range keys {
		required := false
		name := key
		if strings.Index(name, "r@") == 0 {
			name = name[2:]
			required = true
		}
		fieldType := ""
		innerType := ""
		tpl := mp[key]
		switch tpl.(type) {
		case int, int8, int16, int32, int64:
			fieldType = "int"
		case float32, float64:
			f := reflect.ValueOf(tpl).Float()
			i := int64(f)
			if f-float64(i) < 0.0001 {
				fieldType = "int"
			} else {
				fieldType = "double"
			}
		case string:
			fieldType = "String"
		case bool:
			fieldType = "bool"
		case map[string]any:
			innerType = fmt.Sprintf("%s%s", className, strings.ToUpper(name[0:1])+name[1:])
			fieldType = innerType
		case []any:
			innerType = fmt.Sprintf("%s%s", className, strings.ToUpper(name[0:1])+name[1:])
			fieldType = fmt.Sprintf("List<%s>", innerType)
		default:
			fmt.Println("reflect.TypeOf(tpl)----->", reflect.TypeOf(tpl))
			panic("unknown type")
		}
		field := &jsonField{
			key:       key,
			name:      name,
			required:  required,
			fieldType: fieldType,
			innerType: innerType,
			template:  tpl,
		}
		ret = append(ret, field)
	}
	return ret
}

type jsonField struct {
	key       string
	name      string
	fieldType string
	innerType string
	required  bool
	template  any
}

func (j *jsonField) dartTypeName() string {
	if j.required {
		return j.fieldType
	} else {
		return j.fieldType + "?"
	}
}

func (j *jsonField) isListType() bool {
	return strings.HasPrefix(j.fieldType, "List<")
}

func (j *jsonField) isBuiltinType() bool {
	return len(j.innerType) == 0
}

func (j *jsonField) isObjectType() bool {
	return j.fieldType == j.innerType
}

func (j *jsonField) String() string {
	return fmt.Sprintf("%s;%s;%v", j.name, j.fieldType, j.required)
}

type codeLine struct {
	content string
	indent  int
}

func (c *codeLine) addIndent(i int) *codeLine {
	if strings.TrimSpace(c.content) == "" {
		return emptyLine()
	}
	c.indent += i
	return c
}

func (c *codeLine) String() string {
	return fmt.Sprintf("%s%s", strings.Repeat(" ", c.indent), c.content)
}

func emptyLine() *codeLine {
	return &codeLine{content: "", indent: 0}
}

func line(content string) *codeLine {
	return &codeLine{content: content, indent: 0}
}

func indentLine(content string, indent int) *codeLine {
	return &codeLine{content: content, indent: indent}
}
