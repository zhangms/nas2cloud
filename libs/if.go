package libs

func IF(exp bool, a any, b any) any {
	if exp {
		return a
	} else {
		return b
	}
}
