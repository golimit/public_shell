#!/bin/bash

job_name=$(curl -s ip.limitgo.win | head -n 1 | grep -Eow "[0-9].+[0-9]+")
instance_name=$(ip a | grep inet | grep -vE "127.0.0.1|inet6|docker" | awk '{print $2}' | tr -d "addr:" | cut -d'/' -f 1 | head -n 1)
if [ $job_name == "" ];then
	job_name="fetch failed"
fi

# 依赖函数
function centos_yilai() {

## 检查lsscsi
ls /usr/bin/lsscsi > /dev/null 2>&1
if [[ $? -ne 0 ]]; then
yum -y install lsscsi*
fi

}

function ubuntu_yilai() {
# 赋权，注意get后修改echo的密码
echo "$u_password" | sudo -S ls

## 检查lsscsi
ls /usr/bin/lsscsi > /dev/null 2>&1
if [[ $? -ne 0 ]]; then
sudo apt-get -y install lsscsi*
fi
}

# 判断系统并且安装相关依赖
if [[ -f /etc/redhat-release ]];then
	echo -e "${greenbg}开始检测 Centos 依赖环境${plain}"
	centos_yilai
else
	echo -e "${greenbg}开始检测 Ubuntu 依赖环境${plain}"
	ubuntu_yilai
fi

# 检测系统盘
systemdisk=`sudo df -h | grep -vE "tmpfs|mapper|loop|udev" | grep /dev/ | grep boot | sed '2,999d' | awk '{print $1}' | cut -d'/' -f 3`
systemdisk_nvme=`sudo df -h | grep -vE "tmpfs|mapper|loop|udev" | grep /dev/ | grep boot | sed '2,999d' | awk '{print $1}' | cut -d'/' -f 3 | grep nvme | wc -l`
if [ $systemdisk_nvme == 1 ];then
        systemdisk=`echo $systemdisk | grep -Eo "nvme[0-9]n[0-9]"`
else
        systemdisk=`echo $systemdisk | sed 's/[0-9]//g'`
fi

# 时间
## 获取时间戳
srv_time=`date '+%s'`
## 获取系统时间
srv_now_time=`date "+%Y-%m-%d %H:%M:%S"`

# CPU的名称
CPUmode=`cat /proc/cpuinfo| grep "model name" | cut -d':' -f 2 | uniq | sed 's/^ //g'`
# CPU的实际个数
CPUs=`cat /proc/cpuinfo| grep "physical id"| sort| uniq| wc -l`
# CPU的核心数
CPUCores=`cat /proc/cpuinfo| grep "cpu cores"| uniq | cut -d':' -f 2 | sed 's/ //g'`
# CPU的线程数
CPUProc=`cat /proc/cpuinfo| grep "processor"| wc -l`
# CPU的主频
CPUMHz=`cat /proc/cpuinfo |grep MHz | uniq | cut -d':' -f 2 | sed 's/ //g' | cut -d'.' -f 1 | sed '2,999 d'`

# 内存总容量
Memoryzongrongliang=`lsmem |grep "Total\ online\ memory" | cut -d':' -f 2 | sed 's/ //g'`
# 内存条数量
Memoryshuliang=`sudo dmidecode|grep -P -A5 "Memory\s+Device"|grep Size|grep -v Range |grep -v "No Module Installed" |wc -l`
# 单内存条容量
Memorydanrongliang=`sudo dmidecode|grep -P -A5 "Memory\s+Device"|grep Size|grep -v Range |grep -v "No Module Installed" |head -1 | cut -d':' -f 2 | sed 's/ //g'`
# 内存频率
Memorypinlv=`sudo dmidecode|grep -P -A20 "Memory\s+Device"|grep Speed |grep -v "Configured" |sort -n |uniq | grep -v "Unknown" | cut -d':' -f 2 | sed 's/ //g' | sed '2,999 d'`
# 内存品牌
Memorypinpai=`sudo dmidecode|grep -P -A20 "Memory\s+Device"|grep Manufacturer |grep -vE "Not Specified|Unknown" |sort -n |uniq | grep -v "NO DIMM" | cut -d':' -f 2 | sed 's/ //g'`
# 内存值转换
if [ $Memorydanrongliang == '16384MB' ];then
	Memorydanrongliang="16GB"
fi

# 硬盘数量统计
# 系统总盘数
#systemdisktotal=`lsscsi -s | grep disk | wc -l`
systemdisktotal=`lsblk | grep -Eio "nvme[0-9]+n|sd[a-Z]+" | uniq | wc -l`
# 系统盘
#systemdisknum=`lsscsi -s | grep "GB" | wc -l`
systemdiskname=$(echo $systemdisk)
systemdisknum=$(echo $systemdisk | wc -l)
systemdisksize=$(sudo df -h | grep -E "/$" | awk '{ print $2}' | head -n 1)
# 数据盘
datadisknum=`lsscsi -s | grep -E "12.0TB|14.0TB|16.0TB" | wc -l`
# 数据盘大小
datadisksize=`lsscsi -s | grep -Eo "12.0TB|14.0TB|16.0TB" | uniq | sed '2,999d'`
# NVME盘
nvmedisknum=`lsblk | grep '^nvme' | wc -l`
#nvmedisknum=`lsscsi -s | grep 'nvme' | wc -l`
# NVME盘大小
nvmedisksize=`lsblk | grep "^nvme" | grep -v "$systemdiskname" | grep -Eo "[0-9]+.[0-9+][G|T]" | sed '2,999d'`
#nvmedisksize=`lsscsi -s | grep 'nvme' | grep -Eo "[0-9].[0-9]+TB" | uniq | sed '2,999d'`

# 服务器信息
serverinfo1=`sudo dmidecode | grep 'Product Name' | sed '2d' | cut -d':' -f 2 | sed 's/ //'`
serverinfo2=`sudo dmidecode | grep 'Product Name' | sed '1d' | cut -d':' -f 2 | sed 's/ //'`
# 系统OS的版本信息
systemos=`cat /etc/os-release | grep PRETTY_NAME | cut -d'=' -f 2 | sed 's/"//g'`

# 显卡个数
#server_gpu_number=`sudo lspci | grep -Eic "[R|G]TX"`
#server_gpt_name=`sudo lspci | grep -Ei "[R|G]TX" | grep -o "GeForce [R|G]TX [0-9]* Ti" | uniq`
server_gpu_number=`lspci | grep -i vga | grep -v Graphics | wc -l`
server_gpt_name=`lspci | grep -i vga | grep -v Graphics | grep -Eo "GeForce [R|G]TX [0-9]+ [a-Z]+" | uniq`
if [[ $server_gpu_number -ne 0 && $server_gpt_name == "" ]];then
        echo -e "${greenbg}系统显卡为十六进制，开始进行网络查询，确保网络可用！${plain}"
        server_gpt_nameid=`lspci | grep -i vga | grep -v Graphics | grep -Eio "NVIDIA Corporation Device [0-9]+" | grep -oE "[0-9]+" | uniq | sed '2,999d'`
        server_gpt_name=`curl -s http://pci-ids.ucw.cz/mods/PC/10de/$server_gpt_nameid | grep -Eio "nvidia+ g[a-z]+ [R|G][a-z]+ [0-9]+ [a-z]* [a-z]*"`
fi

curl --connect-timeout 10 --retry 2 --retry-delay 3 -X POST 'https://hkapi.limitgo.win/mysql/public_info.php' \
--form args="public_info" \
--form time="$srv_time" \
--form job_name="$job_name" \
--form instance_name="$instance_name" \
--form cpumode="$CPUmode" \
--form cpus="$CPUs" \
--form cpucores="$CPUCores" \
--form cpuproc="$CPUProc" \
--form cpumhz="$CPUMHz" \
--form Memoryzongrongliang="$Memoryzongrongliang" \
--form Memoryshuliang="$Memoryshuliang" \
--form Memorydanrongliang="$Memorydanrongliang" \
--form Memorypinlv="$Memorypinlv" \
--form Memorypinpai="$Memorypinpai" \
--form systemdisktotal="$systemdisktotal" \
--form systemdisknum="$systemdisknum" \
--form systemdisksize="$systemdisksize" \
--form datadisknum="$datadisknum" \
--form datadisksize="$datadisksize" \
--form nvmedisknum="$nvmedisknum" \
--form nvmedisksize="$nvmedisksize" \
--form serverinfo1="$serverinfo1" \
--form serverinfo2="$serverinfo2" \
--form systemos="$systemos" \
--form server_gpu_number="$server_gpu_number" \
--form server_gpt_name="$server_gpt_name"

# End
echo "脚本执行成功，数据已上传"
