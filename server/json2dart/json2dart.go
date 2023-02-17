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

const methodIndent = 2
const step = 2

func genDartClass(className string, mp map[string]any, classes *[]string) {
	keys := make([]string, 0, len(mp))
	for key := range mp {
		keys = append(keys, key)
	}
	sort.Slice(keys, func(i, j int) bool {
		return strings.Compare(keys[i], keys[j]) < 0
	})
	fields := getFields(className, keys, mp)

	codeLines := make([]*codeLine, 0)
	codeLines = append(codeLines, noIndentLine(fmt.Sprintf("class %s {", className)))
	codeLines = append(codeLines, genFieldsPart(fields, methodIndent)...)
	codeLines = append(codeLines, emptyLine())
	codeLines = append(codeLines, genConstructor(className, fields, methodIndent)...)
	codeLines = append(codeLines, emptyLine())
	codeLines = append(codeLines, genFromMap(className, fields, methodIndent)...)
	codeLines = append(codeLines, emptyLine())
	codeLines = append(codeLines, genToMap(fields, methodIndent)...)
	codeLines = append(codeLines, emptyLine())
	codeLines = append(codeLines, genFromJson(className, fields, methodIndent)...)
	codeLines = append(codeLines, emptyLine())
	codeLines = append(codeLines, genToJson(className, fields, methodIndent)...)
	codeLines = append(codeLines, emptyLine())
	codeLines = append(codeLines, genToString(className, fields, methodIndent)...)
	codeLines = append(codeLines, emptyLine())
	codeLines = append(codeLines, genCopyWith(className, fields, methodIndent)...)
	codeLines = append(codeLines, noIndentLine("}")) //end class
	ret := make([]string, 0)
	for _, line := range codeLines {
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

func genCopyWith(className string, fields []*jsonField, indent int) []*codeLine {
	ret := make([]*codeLine, 0)
	ret = append(ret, line(fmt.Sprintf("%s copyWith({", className), indent))
	bodyIndent := indent + step
	for _, field := range fields {
		ret = append(ret, line(fmt.Sprintf("%s %s,", field.fieldType+"?", field.name), bodyIndent))
	}
	ret = append(ret, line("}) {", indent))
	ret = append(ret, line(fmt.Sprintf("return %s(", className), bodyIndent))
	for _, field := range fields {
		ret = append(ret, line(fmt.Sprintf("%s: %s ?? this.%s,", field.name, field.name, field.name), bodyIndent+step))
	}
	ret = append(ret, line(");", bodyIndent))
	ret = append(ret, line("}", indent))
	return ret
}

func genToString(className string, fields []*jsonField, indent int) []*codeLine {
	ret := make([]*codeLine, 0)
	ret = append(ret, line("@override", indent))
	ret = append(ret, line("String toString() {return toJson();}", indent))
	return ret
}

func genToJson(className string, fields []*jsonField, indent int) []*codeLine {
	ret := make([]*codeLine, 0)
	ret = append(ret, line("String toJson() => json.encode(toMap());", indent))
	return ret
}

func genFromJson(className string, fields []*jsonField, indent int) []*codeLine {
	ret := make([]*codeLine, 0)
	ret = append(ret, line(fmt.Sprintf("factory %s.fromJson(String data) {", className), indent))
	ret = append(ret, line(fmt.Sprintf("return %s.fromMap(json.decode(data) as Map<String, dynamic>);", className), indent+step))
	ret = append(ret, line("}", indent))
	return ret
}

func genToMap(fields []*jsonField, indent int) []*codeLine {
	ret := make([]*codeLine, 0)
	ret = append(ret, line("Map<String, dynamic> toMap() => {", indent))
	for _, field := range fields {
		bodyIndent := indent + step
		if field.isBuiltinType() {
			ret = append(ret, line(fmt.Sprintf("'%s': %s,", field.name, field.name), bodyIndent))
		}
		if field.isObjectType() && field.required {
			ret = append(ret, line(fmt.Sprintf("'%s': %s.toMap(),", field.name, field.name), bodyIndent))
		}
		if field.isObjectType() && !field.required {
			ret = append(ret, line(fmt.Sprintf("'%s': %s?.toMap(),", field.name, field.name), bodyIndent))
		}
		if field.isListType() && field.required {
			ret = append(ret, line(fmt.Sprintf("'%s': %s.map((e) => e.toMap()).toList(),", field.name, field.name), bodyIndent))
		}
		if field.isListType() && !field.required {
			ret = append(ret, line(fmt.Sprintf("'%s': %s?.map((e) => e.toMap()).toList(),", field.name, field.name), bodyIndent))
		}
	}
	ret = append(ret, line("};", indent))
	return ret
}

func genFromMap(className string, fields []*jsonField, indent int) []*codeLine {
	ret := make([]*codeLine, 0)
	ret = append(ret, line(fmt.Sprintf("factory %s.fromMap(Map<String, dynamic> data) {", className), indent))
	ret = append(ret, line(fmt.Sprintf("return %s(", className), indent+step))

	for _, field := range fields {
		bodyIndent := indent + 2*step
		if field.isBuiltinType() {
			ret = append(ret, line(fmt.Sprintf("%s: data['%s'] as %s,", field.name, field.name, field.dartTypeName()), bodyIndent))
		}
		if field.isObjectType() && field.required {
			ret = append(ret, line(fmt.Sprintf("%s: %s.fromMap(data['%s'] as Map<String, dynamic>),", field.name, field.innerType, field.name), bodyIndent))
		}
		if field.isObjectType() && !field.required {
			ret = append(ret, line(fmt.Sprintf("%s: data['%s']==null ? null : %s.fromMap(data['%s'] as Map<String, dynamic>),", field.name, field.name, field.innerType, field.name), bodyIndent))
		}
		if field.isListType() && field.required {
			ret = append(ret, line(fmt.Sprintf("%s: (data['%s'] as List<dynamic>).map((e) => %s.fromMap(e as Map<String, dynamic>)).toList(),", field.name, field.name, field.innerType), bodyIndent))
		}
		if field.isListType() && !field.required {
			ret = append(ret, line(fmt.Sprintf("%s: (data['%s'] as List<dynamic>?)?.map((e) => %s.fromMap(e as Map<String, dynamic>)).toList(),", field.name, field.name, field.innerType), bodyIndent))
		}
	}
	ret = append(ret, line(");", indent+step))
	ret = append(ret, line("}", indent))
	return ret
}

func genConstructor(className string, fields []*jsonField, indent int) []*codeLine {
	ret := make([]*codeLine, 0)
	ret = append(ret, line(className+"({", indent))
	for _, field := range fields {
		required := ""
		if field.required {
			required = "required "
		}
		ret = append(ret, line(fmt.Sprintf("%sthis.%s,", required, field.name), indent+step))
	}
	ret = append(ret, line("});", indent))
	return ret
}

func genFieldsPart(fields []*jsonField, indent int) []*codeLine {
	ret := make([]*codeLine, 0)
	for _, field := range fields {
		ret = append(ret, line(fmt.Sprintf("%s %s;", field.dartTypeName(), field.name), indent))
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
		case int:
		case float64:
			if strings.Index(fmt.Sprintf("%v", tpl), ".") > 0 {
				fieldType = "double"
			} else {
				fieldType = "int"
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

func (c *codeLine) String() string {
	return fmt.Sprintf("%s%s", strings.Repeat(" ", c.indent), c.content)
}

func emptyLine() *codeLine {
	return &codeLine{content: "", indent: 0}
}

func noIndentLine(content string) *codeLine {
	return &codeLine{content: content, indent: 0}
}

func line(content string, indent int) *codeLine {
	return &codeLine{content: content, indent: indent}
}
