package cmd

var (
	profile = "dev"
	port    = 7001
	action  = "start"
)

var gitCommit, gitDate string

func init() {
	//logger.Info("gitCommit", gitCommit, "gitDate", gitDate)
	//args := os.Args[1:]
	//if len(args) > 0 && strings.Contains(args[0], "-test") {
	//	action = "test"
	//	return
	//}
	//flag.StringVar(&profile, "profile", "dev", "")
	//flag.StringVar(&action, "action", "start", "")
	//flag.IntVar(&port, "port", 8080, "")
	//flag.Parse()
	//if !IsStarting() {
	//	return
	//}
	//logger.Info("starting profile active", profile)
}
