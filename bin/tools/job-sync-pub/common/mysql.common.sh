#!/bin/bash



source "../etc/tool.conf"  
MYSQL="`which mysql` --connect_timeout=10 -B"


pusername=$SOURCE_SERVER_USERNAME
#ppassword=$SOURCE_SERVER_PASSWORD
phost=$SOURCE_SERVER_IPADDRESS
pport=$SOURCE_SERVER_PORT
pdatabase=$SOURCE_SERVER_DATABASE
pmysql_para=" -h$phost -u$pusername -P$pport -D $pdatabase  -s -e "
##功能:在SOURCE服务器上执行sql语句
MYSQLS="$MYSQL $pmysql_para"


pusername=$TARGET_SERVER_USERNAME
#ppassword=$TARGET_SERVER_PASSWORD
phost=$TARGET_SERVER_IPADDRESS
pport=$TARGET_SERVER_PORT
pdatabase=$TARGET_SERVER_DATABASE
pmysql_para=" -h$phost -u$pusername -P$pport -D $pdatabase -s -e "
##功能:在TARGET服务器上执行sql语句
MYSQLT="$MYSQL $pmysql_para"