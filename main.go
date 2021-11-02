package main

import (
	"flag"
	"fmt"
	"github.com/op/go-logging"
	"log"
	"os"
	"os/signal"
	"syscall"
	_ "unsafe"
	"x-ui/config"
	"x-ui/database"
	"x-ui/logger"
	"x-ui/v2ui"
	"x-ui/web"
	"x-ui/web/global"
	"x-ui/web/service"
)

func runWebServer() {
	log.Printf("%v %v", config.GetName(), config.GetVersion())

	switch config.GetLogLevel() {
	case config.Debug:
		logger.InitLogger(logging.DEBUG)
	case config.Info:
		logger.InitLogger(logging.INFO)
	case config.Warn:
		logger.InitLogger(logging.WARNING)
	case config.Error:
		logger.InitLogger(logging.ERROR)
	default:
		log.Fatal("cấp độ nhật ký không xác định:", config.GetLogLevel())
	}

	err := database.InitDB(config.GetDBPath())
	if err != nil {
		log.Fatal(err)
	}

	var server *web.Server

	server = web.NewServer()
	global.SetWebServer(server)
	err = server.Start()
	if err != nil {
		log.Println(err)
		return
	}

	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGHUP, syscall.SIGTERM, syscall.SIGKILL)
	for {
		sig := <-sigCh

		switch sig {
		case syscall.SIGHUP:
			err := server.Stop()
			if err != nil {
				logger.Warning("lỗi dừng máy chủ:", err)
			}
			server = web.NewServer()
			global.SetWebServer(server)
			err = server.Start()
			if err != nil {
				log.Println(err)
				return
			}
		default:
			server.Stop()
			return
		}
	}
}

func resetSetting() {
	err := database.InitDB(config.GetDBPath())
	if err != nil {
		fmt.Println(err)
		return
	}

	settingService := service.SettingService{}
	err = settingService.ResetSettings()
	if err != nil {
		fmt.Println("đặt lại cài đặt không thành công:", err)
	} else {
		fmt.Println("đặt lại cài đặt thành công")
	}
}

func updateSetting(port int, username string, password string) {
	err := database.InitDB(config.GetDBPath())
	if err != nil {
		fmt.Println(err)
		return
	}

	settingService := service.SettingService{}

	if port > 0 {
		err := settingService.SetPort(port)
		if err != nil {
			fmt.Println("đặt cổng không thành công:", err)
		} else {
			fmt.Printf("đặt port %v thành công", port)
		}
	}
	if username != "" || password != "" {
		userService := service.UserService{}
		err := userService.UpdateFirstUser(username, password)
		if err != nil {
			fmt.Println("đặt tên người dùng và mật khẩu không thành công:", err)
		} else {
			fmt.Println("đặt tên người dùng và mật khẩu thành công")
		}
	}
}

func main() {
	if len(os.Args) < 2 {
		runWebServer()
		return
	}

	var showVersion bool
	flag.BoolVar(&showVersion, "v", false, "hiển thị phiên bản")

	runCmd := flag.NewFlagSet("run", flag.ExitOnError)

	v2uiCmd := flag.NewFlagSet("v2-ui", flag.ExitOnError)
	var dbPath string
	v2uiCmd.StringVar(&dbPath, "db", "/etc/v2-ui/v2-ui.db", "đặt đường dẫn tệp v2-ui db")

	settingCmd := flag.NewFlagSet("setting", flag.ExitOnError)
	var port int
	var username string
	var password string
	var reset bool
	settingCmd.BoolVar(&reset, "cài lại", false, "khôi phục tất cả cài đặt")
	settingCmd.IntVar(&port, "port", 0, "đặt cổng bảng điều khiển")
	settingCmd.StringVar(&username, "tên người dùng", "", "đặt tên người dùng đăng nhập")
	settingCmd.StringVar(&password, "mật khẩu", "", "đặt mật khẩu đăng nhập")

	oldUsage := flag.Usage
	flag.Usage = func() {
		oldUsage()
		fmt.Println()
		fmt.Println("Lệnh:")
		fmt.Println("    run            chạy bảng điều khiển web")
		fmt.Println("    v2-ui          di chuyển hình thức v2-ui")
		fmt.Println("    setting        thiết lập cài đặt")
	}

	flag.Parse()
	if showVersion {
		fmt.Println(config.GetVersion())
		return
	}

	switch os.Args[1] {
	case "run":
		err := runCmd.Parse(os.Args[2:])
		if err != nil {
			fmt.Println(err)
			return
		}
		runWebServer()
	case "v2-ui":
		err := v2uiCmd.Parse(os.Args[2:])
		if err != nil {
			fmt.Println(err)
			return
		}
		err = v2ui.MigrateFromV2UI(dbPath)
		if err != nil {
			fmt.Println("di chuyển từ v2-ui không thành công:", err)
		}
	case "setting":
		err := settingCmd.Parse(os.Args[2:])
		if err != nil {
			fmt.Println(err)
			return
		}
		if reset {
			resetSetting()
		} else {
			updateSetting(port, username, password)
		}
	default:
		fmt.Println("Các lệnh con ngoại trừ 'run' hoặc 'v2-ui' hoặc 'setting' ")
		fmt.Println()
		runCmd.Usage()
		fmt.Println()
		v2uiCmd.Usage()
		fmt.Println()
		settingCmd.Usage()
	}
}
