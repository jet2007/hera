#!/bin/bash

source "$HOME/.bashrc"
source "$HOME/.bash_profile"
curDir=$(cd `dirname $0`; pwd)
scriptName=`basename $0`
cd ${curDir}
#######################################################################

#######################################################################
##加载conf
source "../etc/tool.conf"  
source "./function.common.sh"   
#######################################################################

#datax核心参数

source_querySql=${1}
target_tableName=${2}
target_preSql=${3}
target_postSql=${4}



datax_paras="-Dreader_username='$TARGET_SERVER_USERNAME' \
            -Dreader_password='$TARGET_SERVER_PASSWORD' \
            -Dreader_jdbcurl='$TARGET_SERVER_JDBC' \
            -Dreader_querySql=\"$source_querySql\""

datax_paras="${datax_paras} \
            -Dwriter_username='$SOURCE_SERVER_USERNAME' \
            -Dwriter_password='$SOURCE_SERVER_PASSWORD' \
            -Dwriter_jdbcUrl='$SOURCE_SERVER_JDBC'  \
            -Dwriter_preSql=\"$target_preSql\" \
            -Dwriter_postSql=\"$target_postSql\" \
            -Dwriter_tableName='$target_tableName' "

            



#######################################################################
####执行脚本####
#判断datax.py文件是否存在，不存在直接退出
if [ ! -f "$DATAX_BIN" ]; then
   fn_error_job_failure_wirte_to_log "配置文件中$DATAX_BIN配置错误"
fi
exec_json_name='./mysql2mysql.datax.json'

#echo "python $DATAX_BIN $exec_json_name -p \"${datax_paras}\""

python $DATAX_BIN $exec_json_name -p "${datax_paras}" > /dev/null



