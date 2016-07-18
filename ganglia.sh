#!/bin/bash
OS=`sed -n '1p' /etc/issue |awk '{print $1}'`
name='"my cluster"'
#IP=`ifconfig eth0 |awk -F '[ :]+'  'NR==2{print $4}'`
####host IP###
IP=192.168.56.138
#echo $name
CentOS_install(){
###### setting yum #######
#mkdir  /etc/yum.repos.d/backup
#mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/backup
#curl -o /etc/yum.repos.d/aliyun.repo $repourl
#wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-6.repo
#yum install http://mirrors.hustunique.com/epel//6/x86_64/epel-release-6-8.noarch.rpm    

yum clean all
yum makecache

###yum for packge##
yum -y install ganglia-gmond
sed -i 's@name = "unspecified"@name = '"$name"'@' /etc/ganglia/gmond.conf
sed -i 's/mcast_join = 239.2.11.71/#mcast_join = 239.2.11.71/g' /etc/ganglia/gmond.conf
sed -i '50a   host='$IP'' /etc/ganglia/gmond.conf
sed -i '/bind = 239.2.11.71/ s/^/#/' /etc/ganglia/gmond.conf
sed -i '/retry_bind = true/ s/^/#/' /etc/ganglia/gmond.conf
/etc/init.d/gmond start
chkconfig gmond on

}

Ubuntu_install(){
apt-get update

sudo apt-get install ganglia-monitor -y 
sed -i 's@name = "unspecified"@name = '"$name"'@' /etc/ganglia/gmond.conf
#sed -i "s@name = \"unspecified\"@name = $name@" /etc/ganglia/gmond.conf
sed -i 's/mcast_join = 239.2.11.71/#mcast_join = 239.2.11.71/g' /etc/ganglia/gmond.conf
sed -i '35a   host='$IP'' /etc/ganglia/gmond.conf
sed -i '/bind = 239.2.11.71/ s/^/#/' /etc/ganglia/gmond.conf

/etc/init.d/ganglia-monitor start
update-rc.d ganglia-monitor defaults



}
#######main fun########
if [ $UID -ne 0 ];then
   echo -e "\033[31m You must chang root to run this script! \033[0m"
   exit 0
fi

##### check sys #####
if [ $OS == 'CentOS' ];then
   CentOS_install
   #echo "centos"
elif [ $OS == 'Ubuntu' ]; then
   Ubuntu_install
   #echo "ubuntu"
else
   echo -e "\033[31m $OS NOT ACCEPT TO THIS SCRIPTS ,IT WILL BE EXIT! \033[0m" && exit 20
fi
