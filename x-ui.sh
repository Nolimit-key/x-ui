#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}Cảnh báo: ${plain} Sử dụng quyền truy cập root để sử dụng lệnh này！\n" && exit 1

# check os
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
else
    echo -e "${red}Không tìm thấy phiên bản nào!${plain}\n" && exit 1
fi

os_version=""

# os version
if [[ -f /etc/os-release ]]; then
    os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
fi
if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
    os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
fi

if [[ x"${release}" == x"centos" ]]; then
    if [[ ${os_version} -le 6 ]]; then
        echo -e "${red}Vui lòng sử dụng hệ điều hành CentOS 7 trở lên！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "${red}Vui lòng sử dụng hệ điều hành Ubuntu 16 trở lên！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}Vui lòng sử dụng hệ điều hành Debian 8 trở lên！${plain}\n" && exit 1
    fi
fi

confirm() {
    if [[ $# > 1 ]]; then
        echo && read -p "$1 [默认$2]: " temp
        if [[ x"${temp}" == x"" ]]; then
            temp=$2
        fi
    else
        read -p "$1 [y/n]: " temp
    fi
    if [[ x"${temp}" == x"y" || x"${temp}" == x"Y" ]]; then
        return 0
    else
        return 1
    fi
}

confirm_restart() {
    confirm "Bạn có chắc khởi động lại bảng điều khiển hay không? Khởi động lại bảng điều khiển cũng sẽ khởi động lại xray " "y"
    if [[ $? == 0 ]]; then
        restart
    else
        show_menu
    fi
}

before_show_menu() {
    echo && echo -n -e "${yellow}Enter để quay lại menu chính: ${plain}" && read temp
    show_menu
}

install() {
    bash <(curl -Ls https://github.com/vietdungit/x-ui/raw/master/x-ui.sh)
    if [[ $? == 0 ]]; then
        if [[ $# == 0 ]]; then
            start
        else
            start 0
        fi
    fi
}

update() {
    confirm "Chức năng này sẽ buộc cài đặt lại phiên bản mới nhất hiện tại và dữ liệu sẽ không bị mất. Bạn có muốn tiếp tục không? " "n"
    if [[ $? != 0 ]]; then
        echo -e "${red}Đã hủy${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 0
    fi
    bash <(curl -Ls https://raw.githubusercontent.com/vietdungit/x-ui/master/install.sh)
    if [[ $? == 0 ]]; then
        echo -e "${green}Cập nhật hoàn tất và bảng điều khiển đã được tự động khởi động lại ${plain}"
        exit 0
    fi
}

uninstall() {
    confirm "Bạn có chắc chắn muốn gỡ cài đặt bảng điều khiển, xray cũng sẽ gỡ cài đặt? " "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    systemctl stop x-ui
    systemctl disable x-ui
    rm /etc/systemd/system/x-ui.service -f
    systemctl daemon-reload
    systemctl reset-failed
    rm /etc/x-ui/ -rf
    rm /usr/local/x-ui/ -rf

    echo ""
    echo -e "Quá trình gỡ cài đặt thành công. Nếu bạn muốn xóa tập lệnh này, hãy thoát tập lệnh và chạy  ${green}rm /usr/bin/x-ui -f${plain} Xóa bỏ"
    echo ""

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

reset_user() {
    confirm "Bạn có chắc chắn muốn đặt lại tên người dùng và mật khẩu cho quản trị viên không?" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    /usr/local/x-ui/x-ui setting -username admin -password admin
    echo -e "Tên người dùng và mật khẩu đã được đặt lại thành  ${green}admin${plain}，Vui lòng khởi động lại bảng điều khiển ngay bây giờ"
    confirm_restart
}

reset_config() {
    confirm "Bạn có chắc chắn muốn đặt lại tất cả cài đặt bảng không? Dữ liệu tài khoản sẽ không bị mất, tên người dùng và mật khẩu sẽ không bị thay đổi" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    /usr/local/x-ui/x-ui setting -reset
    echo -e "Tất cả cài đặt bảng điều khiển đã được đặt lại về giá trị mặc định, bây giờ vui lòng khởi động lại bảng điều khiển và sử dụng cổng mặc định ${green}54321${plain} để truy cập bảng điều khiển"
    confirm_restart
}

set_port() {
    echo && echo -n -e "Nhập số cổng[1-65535]: " && read port
    if [[ -z "${port}" ]]; then
        echo -e "${yellow}Đã hủy${plain}"
        before_show_menu
    else
        /usr/local/x-ui/x-ui setting -port ${port}
        echo -e "Sau khi thiết lập cổng, vui lòng khởi động lại bảng điều khiển và sử dụng cổng mới đặt  ${green}${port}${plain} để truy cập bảng điều khiển"
        confirm_restart
    fi
}

start() {
    check_status
    if [[ $? == 0 ]]; then
        echo ""
        echo -e "${green}Bảng điều khiển đang chạy. Nếu cần khởi động lại, vui lòng chọn khởi động lại ${plain}"
    else
        systemctl start x-ui
        sleep 2
        check_status
        if [[ $? == 0 ]]; then
            echo -e "${green}x-ui đang chạy${plain}"
        else
            echo -e "${red}Bảng điều khiển không khởi động được. Có thể do thời gian khởi động vượt quá hai giây. Vui lòng kiểm tra thông tin nhật ký ${plain}"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

stop() {
    check_status
    if [[ $? == 1 ]]; then
        echo ""
        echo -e "${green}Bảng điều khiển đã dừng, không cần dừng lại ${plain}"
    else
        systemctl stop x-ui
        sleep 2
        check_status
        if [[ $? == 1 ]]; then
            echo -e "${green}x-ui và xray đã dừng thành công ${plain}"
        else
            echo -e "${red}Bảng điều khiển không dừng được. Có thể do thời gian dừng vượt quá hai giây. Vui lòng kiểm tra thông tin nhật ký ${plain}"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

restart() {
    systemctl restart x-ui
    sleep 2
    check_status
    if [[ $? == 0 ]]; then
        echo -e "${green}x-ui và xray khởi động lại thành công ${plain}"
    else
        echo -e "${red}Khởi động lại bảng điều khiển không thành công, có thể do thời gian khởi động vượt quá hai giây, vui lòng kiểm tra thông tin nhật ký ${plain}"
    fi
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

status() {
    systemctl status x-ui -l
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

enable() {
    systemctl enable x-ui
    if [[ $? == 0 ]]; then
        echo -e "${green}cai đặt x-ui được thiết lập để bắt đầu sau khi khởi động ${plain}"
    else
        echo -e "${red}cài đặt x-ui không thể tự động khởi động sau khi khởi động ${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

disable() {
    systemctl disable x-ui
    if [[ $? == 0 ]]; then
        echo -e "${green}Hủy tự động khởi động x-ui thành công ${plain}"
    else
        echo -e "${red}x-ui Hủy bỏ lỗi khởi động ${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_log() {
    journalctl -u x-ui.service -e --no-pager -f
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

migrate_v2_ui() {
    /usr/local/x-ui/x-ui v2-ui

    before_show_menu
}

install_bbr() {
    bash <(curl -L -s https://raw.githubusercontent.com/vietdungit/blog/master/bbr.sh)
    echo ""
    before_show_menu
}

update_shell() {
    wget -O /usr/bin/x-ui -N --no-check-certificate https://github.com/vietdungit/x-ui/raw/master/x-ui.sh
    if [[ $? != 0 ]]; then
        echo ""
        echo -e "${red}Không thể tải xuống tập lệnh, vui lòng kiểm tra xem máy có thể kết nối với Github hay không!${plain}"
        before_show_menu
    else
        chmod +x /usr/bin/x-ui
        echo -e "${green}Tập lệnh nâng cấp thành công, vui lòng chạy lại tập lệnh ${plain}" && exit 0
    fi
}

# 0: running, 1: not running, 2: not installed
check_status() {
    if [[ ! -f /etc/systemd/system/x-ui.service ]]; then
        return 2
    fi
    temp=$(systemctl status x-ui | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
    if [[ x"${temp}" == x"đang chạy" ]]; then
        return 0
    else
        return 1
    fi
}

check_enabled() {
    temp=$(systemctl is-enabled x-ui)
    if [[ x"${temp}" == x"được kích hoạt" ]]; then
        return 0
    else
        return 1;
    fi
}

check_uninstall() {
    check_status
    if [[ $? != 2 ]]; then
        echo ""
        echo -e "${red}Bảng điều khiển đã được cài đặt, vui lòng không cài đặt lại${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

check_install() {
    check_status
    if [[ $? == 2 ]]; then
        echo ""
        echo -e "${red}Vui lòng cài đặt bảng điều khiển trước${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

show_status() {
    check_status
    case $? in
        0)
            echo -e "Trạng thái bảng điều khiển: ${green}Đã chạy${plain}"
            show_enable_status
            ;;
        1)
            echo -e "Trạng thái bảng điều khiển : ${yellow}Không chạy${plain}"
            show_enable_status
            ;;
        2)
            echo -e "Trạng thái bảng điều khiển : ${red}Chưa cài đặt${plain}"
    esac
    show_xray_status
}

show_enable_status() {
    check_enabled
    if [[ $? == 0 ]]; then
        echo -e "Có tự động khởi động sau khi khởi động không: ${green}có${plain}"
    else
        echo -e "Có tự động khởi động sau khi khởi động không: ${red}không${plain}"
    fi
}

check_xray_status() {
    count=$(ps -ef | grep "xray-linux" | grep -v "grep" | wc -l)
    if [[ count -ne 0 ]]; then
        return 0
    else
        return 1
    fi
}

show_xray_status() {
    check_xray_status
    if [[ $? == 0 ]]; then
        echo -e "tình trạng xray: ${green}chạy${plain}"
    else
        echo -e "tình trạng xray: ${red}không chạy${plain}"
    fi
}

show_usage() {
    echo "x-ui Cách sử dụng lệnh để quản lý : "
    echo "------------------------------------------"
    echo "x-ui              - Menu quản lý màn hình (nhiều chức năng hơn) "
    echo "x-ui start        - Khởi chạy bảng điều khiển x-ui"
    echo "x-ui stop         - Dừng bảng điều khiển x-ui"
    echo "x-ui restart      - Khởi động lại bảng điều khiển x-ui"
    echo "x-ui status       - Xem trạng thái x-ui"
    echo "x-ui enable       - Đặt x-ui tự động khởi động"
    echo "x-ui disable      - Hủy x-ui tự khởi động"
    echo "x-ui log          - Xem nhật ký x-ui"
    echo "x-ui v2-ui        - Di chuyển dữ liệu tài khoản từ bản v2-ui sang x-ui"
    echo "x-ui update       - Cập nhật bảng điều khiển x-ui"
    echo "x-ui install      - Cài đặt bảng điều khiển x-ui"
    echo "x-ui uninstall    - Gỡ cài đặt bảng điều khiển x-ui"
    echo "------------------------------------------"
}

show_menu() {
    echo -e "
  ${green}Quản lý bảng điều khiển x-ui${plain}

  ${green}0.${plain} Lệnh sử dụng
————————————————
  ${green}1.${plain} Cài đặt x-ui
  ${green}2.${plain} Cập nhật x-ui
  ${green}3.${plain} Gỡ cài đặt x-ui
————————————————
  ${green}4.${plain} Đặt lại tên người dùng và mật khẩu
  ${green}5.${plain} Đặt lại cài đặt bảng điều khiển
  ${green}6.${plain} Đặt cổng(Port) bảng điều khiển
————————————————
  ${green}7.${plain} Bắt đầu x-ui
  ${green}8.${plain} Dừng x-ui
  ${green}9.${plain} Khởi động lại x-ui
 ${green}10.${plain} Xem trạng thái x-ui
 ${green}11.${plain} Xem nhật ký x-ui
————————————————
 ${green}12.${plain} Đặt x-ui tự động khởi động
 ${green}13.${plain} Hủy x-ui tự khởi động
————————————————
 ${green}14.${plain} 一 Cài đặt bbr (mới nhất) 
 "
    show_status
    echo && read -p "Vui lòng nhập lựa chọn [0-14]: " num

    case "${num}" in
        0) exit 0
        ;;
        1) check_uninstall && install
        ;;
        2) check_install && update
        ;;
        3) check_install && uninstall
        ;;
        4) check_install && reset_user
        ;;
        5) check_install && reset_config
        ;;
        6) check_install && set_port
        ;;
        7) check_install && start
        ;;
        8) check_install && stop
        ;;
        9) check_install && restart
        ;;
        10) check_install && status
        ;;
        11) check_install && show_log
        ;;
        12) check_install && enable
        ;;
        13) check_install && disable
        ;;
        14) install_bbr
        ;;
        *) echo -e "${red}Vui lòng nhập số chính xác [0-14]${plain}"
        ;;
    esac
}


if [[ $# > 0 ]]; then
    case $1 in
        "bắt đầu ") check_install 0 && start 0
        ;;
        "dừng") check_install 0 && stop 0
        ;;
        "khởi động lại") check_install 0 && restart 0
        ;;
        "tình trạng") check_install 0 && status 0
        ;;
        "cho phép") check_install 0 && enable 0
        ;;
        "vô hiệu") check_install 0 && disable 0
        ;;
        "log") check_install 0 && show_log 0
        ;;
        "v2-ui") check_install 0 && migrate_v2_ui 0
        ;;
        "cập nhật") check_install 0 && update 0
        ;;
        "cài đặt") check_uninstall 0 && install 0
        ;;
        "gỡ bỏ") check_install 0 && uninstall 0
        ;;
        *) show_usage
    esac
else
    show_menu
fi
