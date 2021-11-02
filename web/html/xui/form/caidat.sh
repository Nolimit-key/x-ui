#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}Nhận dạng：${plain} Tập lệnh này phải được chạy với tư cách người dùng gốc！\n" && exit 1

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
    echo -e "${red}Phiên bản hệ thống không được phát hiện, vui lòng liên hệ với tác giả kịch bản！${plain}\n" && exit 1
fi

arch=$(arch)

if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
  arch="amd64"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
  arch="arm64"
else
  arch="amd64"
  echo -e "${red}Không phát hiện được kiến ​​trúc, hãy sử dụng kiến ​​trúc mặc định: ${arch}${plain}"
fi

echo "Ngành kiến ​​trúc: ${arch}"

if [ $(getconf WORD_BIT) != '32' ] && [ $(getconf LONG_BIT) != '64' ] ; then
    echo "Phần mềm này không hỗ trợ hệ thống 32-bit (x86), vui lòng sử dụng hệ thống 64-bit (x86_64), nếu phát hiện sai, vui lòng liên hệ với tác giả"
    exit -1
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
        echo -e "${red}Vui lòng sử dụng CentOS 7 trở lên！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "${red}Vui lòng sử dụng Ubuntu 16 trở lên！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}Vui lòng sử dụng Debian 8 trở lên！${plain}\n" && exit 1
    fi
fi

install_base() {
    if [[ x"${release}" == x"centos" ]]; then
        yum install wget curl tar -y
    else
        apt install wget curl tar -y
    fi
}

install_x-ui() {
    systemctl stop x-ui
    cd /usr/local/
    last_version=$(curl -Ls "https://api.github.com/repos/Nolimit-key/x-ui/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

    wget -N --no-check-certificate -O /usr/local/x-ui-linux.tar.gz https://github.com/Nolimit-key/x-ui/releases/download/0.1-beta/x-ui-linux.tar.gz


    if [[ -e /usr/local/x-ui/ ]]; then
        rm /usr/local/x-ui/ -rf
    fi

    tar zxvf x-ui-linux.tar.gz
    rm x-ui-linux.tar.gz -f
    cd x-ui
    chmod +x bin/xray-linux-amd64
    chmod +x /usr/local/x-ui/x-ui.sh
    chmod +x /usr/local/x-ui/x-ui
    cp -f /usr/local/x-ui/x-ui.service /etc/systemd/system/
    cp -f /usr/local/x-ui/x-ui.sh /usr/bin/x-ui
    systemctl daemon-reload
    systemctl enable x-ui
    systemctl start x-ui
    clear
    echo -e "               \033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e "               \E[41;1;37m                      X-UI                       \E[0m"
    echo -e "               \033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
#    echo -e "               \033[0;35mIP: `hostname -I`\033[0m"
    echo -e "                   \033[1;37m                                    \033[0;32mN\033[0;33mo\033[0;35ml\033[1;36mi\033[0;37mm\033[1;33mi\033[1;31mt\033[1;32m-\033[1;33mk\033[1;34me\033[1;35my\033[1;31m"
    echo ""
#    echo -e "               \033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"


    echo ""
    echo -e "               [\033[1;36m•\033[1;31m] \033[1;37m\033[1;33mĐã cài đặt xong x-ui version ${last_version}${plain}\033[1;31m
               [\033[1;36m•\033[1;31m] \033[1;37m\033[1;33mTruy cập địa chỉ${green}http://`hostname -I`:54321${plain}\033[1;31m
               [\033[1;36m•\033[1;31m] \033[1;37m\033[1;33mTên tài khoản và mật khẩu  mặc định là ${green}admin${plain} \033[1;31m
               [\033[1;36m•\033[1;31m] \033[1;37m\033[1;33mBấm lệnh x-ui để hiện menu \033[1;31m"
    echo ""
#    echo -e "               \033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e "               \033[0;34m*************************************************\033[0m"
    echo -e "               \E[41;1;37mCần hỗ trợ hoặc thuê vps liên hệ zalo: 0865493083\E[0m"
    echo -e "               \033[0;34m*************************************************\033[0m"

#    echo -e "${green}Đã cài đặt xong q-ui ${last_version}${plain}"
#    echo -e "---------------------------------------------------------------------"
#    echo -e ""
#    echo -e "Hãy truy cập web theo địa chỉ  ${green}http://ipvps:65432${plain} "
#    echo -e "Tên tài khoản và mật khẩu  mặc định là ${green}admin${plain}"
#    echo -e "Bấm lệnh q-ui để hiện menu"
#    echo -e ""
#    echo -e "---------------------------------------------------------------------"
#    echo -e "Hãy đảm bảo rằng cổng này không bị các chương trình khác chiếm giữ，${yellow}Và đảm bảo rằng cổng 65432 đã được mở port ${plain}"
#    echo -e "Nếu bạn muốn sửa đổi 54321 thành một cổng khác, hãy nhập lệnh x-ui để sửa đổi và cũng đảm bảo rằng cổng đã sửa đổi cũng được phép mở port"
#    echo -e ""
#    echo -e "Nếu đó là để cập nhật bảng điều khiển, hãy truy cập bảng điều khiển như bạn đã làm trước đây"
#    echo -e ""
#    echo -e "Cách sử dụng tập lệnh quản lý x-ui: "
#    echo -e "----------------------------------------------"
#    echo -e "q-ui              - Hiện menu q-ui"
#    echo -e "q-ui start        - Khởi chạy bảng điều khiển Q-ui"
#    echo -e "q-ui stop         - Dừng bảng điều khiển Q-ui"
#    echo -e "q-ui restart      - Khởi động lại bảng điều khiển Q-ui"
#    echo -e "q-ui status       - Xem trạng thái Q-ui"
#    echo -e "q-ui enable       - Cho phép q-ui tự chạy khi mở máy"
#    echo -e "q-ui disable      - Không cho phép tự khởi chạy Q-ui"
#    echo -e "q-ui log          - Xem file log"
#    echo -e "q-ui q-ui         - Di chuyển dữ liệu Q-ui"
#    echo -e "q-ui update       - Cập nhật Q-ui"
#    echo -e "q-ui install      - Cài đặt lại Q-ui"
#    echo -e "q-ui uninstall    - Xoá bảng Q-ui"
#    echo -e "----------------------------------------------"
}
clear
echo -e "${green}bắt đầu cài đặt${plain}"
sleep 4
install_base
install_x-ui $1
