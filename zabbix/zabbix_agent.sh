#!/bin/bash
USER=zabbix
OS=`sed -n '1p' /etc/issue |awk '{print $1}'`
BASEDIR=/usr/local/src
#url=http://repo.zabbix.com/zabbix/2.2/ubuntu/pool/main/z/zabbix/zabbix_2.2.11.orig.tar.gz
repourl=http://mirrors.aliyun.com/repo/Centos-6.repo
#zabbix_source=`echo $url |awk -F '/' '{print $NF}'`
zabbix_source=zabbix-3.0.0.tar.gz
#zabbix_name=`echo  $zabbix_source|sed  -r 's/zabbix_([0-9]\.[0-9]\.[0-9]{1,2}).*/zabbix-\1/g'`
zabbix_name=`echo  $zabbix_source|sed  -r 's/zabbix-([0-9]\.[0-9]\.[0-9]{1,2}).*/zabbix-\1/g'`
config_dir=/etc/zabbix
#name=zabbixclient


CentOS_agentd(){
###### setting yum #######
mkdir  /etc/yum.repos.d/backup
mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/backup
curl -o /etc/yum.repos.d/aliyun.repo $repourl
##wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-6.repo
#
###### yum install ######
yum -y install gcc gcc-c++ wget curl-devel net-snmp net-snmp-devel perl-DBI ntpdate
#
###### set user && tar #####
groupadd $USER ;useradd -g $USER -s /sbin/nologin $USER
#wget -P $BASEDIR $url
cd $BASEDIR ; wget $url
tar -xf $zabbix_source
cd $zabbix_name
#
###### make config #####
./configure --prefix=/usr/local/zabbix   --enable-agent  --with-net-snmp --with-libcurl
make install
#
#
cp misc/init.d/fedora/core/zabbix_agentd /etc/init.d/
chmod 755 /etc/init.d/zabbix_agentd
sed -i 's#BASEDIR=/usr/local#BASEDIR=/usr/local/zabbix#g' /etc/init.d/zabbix_agentd
#
###### server port #####
cat >> /etc/services << "EOF"
zabbix-agent 10050/tcp Zabbix Agent
zabbix-agent 10050/udp Zabbix Agent
EOF
#
###### config file #####
sed -i 's/Server\=127.0.0.1/Server\='$ip'/g' /usr/local/zabbix/etc/zabbix_agentd.conf
sed -i 's/ServerActive\=127.0.0.1/ServerActive\='$ip'/g' /usr/local/zabbix/etc/zabbix_agentd.conf
sed -i 's/Hostname=Zabbix server/Hostname='$name'/g' /usr/local/zabbix/etc/zabbix_agentd.conf

###### start agentd #####
/usr/local/zabbix/sbin/zabbix_agentd
}


Ubuntu_agentd(){
##### set apt source #####
cp /etc/apt/sources.list /etc/apt/sources.list.bak
cat >/etc/apt/sources.list<<EOF
deb http://mirrors.aliyun.com/ubuntu/ trusty main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ trusty-security main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ trusty-updates main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ trusty-proposed main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ trusty-backports main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ trusty main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ trusty-security main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ trusty-updates main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ trusty-proposed main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ trusty-backports main restricted universe multiverse
EOF
apt-get update

##### apt-get install #####
apt-get install -y make libcurl4-openssl-dev libmysqlclient-dev snmp libsnmp-dev snmpd

##### set user && tar #####
groupadd $USER ;useradd -g $USER -s /sbin/nologin $USER
cd $BASEDIR #; wget $url
tar -xf $zabbix_source
cd $zabbix_name

##### make config #####
./configure --prefix=/usr/local/zabbix   --enable-agent  --with-net-snmp --with-libcurl
make && make install

##### start script #####
cp misc/init.d/debian/zabbix-agent /etc/init.d/
sed -i 's@DAEMON=/usr/local/sbin/${NAME}@DAEMON=/usr/local/zabbix/sbin/${NAME}@g' /etc/init.d/zabbix-agent
chmod 755 /etc/init.d/zabbix-agent

##### config file #####
sed -i 's/Server\=127.0.0.1/Server\='$ip'/g' /usr/local/zabbix/etc/zabbix_agentd.conf
sed -i 's/ServerActive\=127.0.0.1/ServerActive\='$ip'/g' /usr/local/zabbix/etc/zabbix_agentd.conf
sed -i 's/Hostname=Zabbix server/Hostname='$name'/g' /usr/local/zabbix/etc/zabbix_agentd.conf

##### server port #####
cat >> /etc/services << "EOF"
zabbix-agent 10050/tcp Zabbix Agent
zabbix-agent 10050/udp Zabbix Agent
EOF

##### start server #####
#/usr/local/zabbix/sbin/zabbix_agentd
service zabbix-agent start
update-rc.d zabbix-agent defaults

}

##### main #####
##### check user #####
#if [ $UID -ne 0 ]; then
#    echo -e "\033[31m You must chang root to run this script! \033[0m"
#    exit 0
#fi
##### get proxy ip #####
ip=192.168.100.145
name=`hostname`
#while :
#do
#read -p "please input the zabbix-proxy ip:" ip
#read -p "please input the hostname for zabbix agent:" name
#read -p "zabbix proxy ip is : `echo -e "\033[31m $ip \033[0m"`, the hostname is `echo -e "\033[31m $name \033[0m"` sure ? [y/n]" sel
##read -p "zabbix proxy ip is : `echo -e "\033[31m $ip \033[0m"`, sure ? [y/n]" sel
#if [ "$sel" == "y" ];then
# #echo $ip
# echo -e "\033[31m install will begin ... ... \033[0m" && break
#else
# echo -e "\033[33m please input again ! \033[0m"
#fi
#done

##### check sys #####
if [ $OS == 'CentOS' ];then
   CentOS_zagentd
   #echo "centos"
elif [ $OS == 'Ubuntu' ]; then
   Ubuntu_agentd
   #echo "ubuntu"
else
   echo -e "\033[31m $OS NOT ACCEPT TO THIS SCRIPTS ,IT WILL BE EXIT! \033[0m" && exit 20
fi
