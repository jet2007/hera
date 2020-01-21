#!/bin/bash

set +e
source "$HOME/.bashrc"
source "$HOME/.bash_profile"
curDir=$(cd `dirname $0`; pwd)
scriptName=`basename $0`
cd ${curDir}
#######################################################################
#入参

source ../etc/tool.conf
source ../common/function.common.sh
source ../common/mysql.common.sh
source ../common/herameta.common.sh

#定义全局变量
uuid=$(cat /proc/sys/kernel/random/uuid)
parent_groups=''
group_jobs=''
group_jobs_display=''
group_display=''
error_msg=''
input_group_dir='小目录' #只能发布小目录
input_group_dir_id=1 #只能发布小目录
input_group_id='' #入参1 
input_name='' #入参2


# 输入的小目录是否存在
fn_first_check()
{
	local sql="
	SELECT COUNT(1) CNT
	  FROM hera_group
	      WHERE id=$input_group_id and directory=$input_group_dir_id
	"
	export MYSQL_PWD=$SOURCE_SERVER_PASSWORD
    local re=$($MYSQLS "$sql")
	if [ "$re" = '0' ];then
	    return 1
	fi
	group_display=$(fn_source_get_group_display_by_id "$input_group_id")
	parent_groups=$(fn_source_get_group_parents "$input_group_id")
	group_jobs=$(fn_source_get_jobs_in_group "$input_group_id")
	group_jobs_display=$(fn_source_get_jobs_display_in_group "$input_group_id")
}

#发布任务时，准备数据
fn_prepare_data()
{
	local operate_obj=$input_group_dir #当前只支持小目录
	local operate_id=$input_group_id
	local name=$input_name
	local status="发布-申请" 
	local sql="
			INSERT INTO hera_sync_pub_history ( id ,name  ,operate_obj ,operate_id ,status ,gmt_create ,gmt_modified ,remark) 
			VALUES (
			  '$uuid'  
			 ,'$name' 
			 ,'$operate_obj' 
			 , $operate_id 
			 , '$status' 
			 , NOW() 
			 , NOW() 
			 , '' 
			);
	"
	fn_source_exec_sql "$sql" # 

	sql="
		INSERT INTO hera_sync_pub_group 
		SELECT $META_HERA_GROUP_COLUMNS , '$uuid'  
		FROM hera_group 
		where id in ($parent_groups)
	"
	fn_source_exec_sql "$sql" # group数据准备


	sql="
		INSERT INTO hera_sync_pub_job
		SELECT  $META_HERA_JOB_COLUMNS ,  '$uuid' 
		FROM hera_job 
		WHERE id IN ($group_jobs)
	"
	fn_source_exec_sql "$sql" 
}

#  发布任务，传输数据
fn_pub_transfer_data()
{
	local source_querySql="SELECT * FROM hera_sync_pub_history where id='$uuid' "
	local target_tableName="hera_sync_pub_history"
	local target_preSql="SELECT 1;"
	local target_postSql="SELECT 1;"
	sh ../common/src2tgt.datax.sh "$source_querySql" "$target_tableName" "$target_preSql" "$target_postSql" 

	source_querySql="SELECT * FROM hera_sync_pub_group where rs_id='$uuid' "
	target_tableName="hera_sync_pub_group"
	target_preSql="SELECT 1;"
	target_postSql="SELECT 1;"
	sh ../common/src2tgt.datax.sh "$source_querySql" "$target_tableName" "$target_preSql" "$target_postSql" 

	local status='发布-传输数据'
	source_querySql="SELECT * FROM hera_sync_pub_job where rs_id='$uuid' "
	target_tableName="hera_sync_pub_job"
	target_preSql="SELECT 1;"
	target_postSql="update hera_sync_pub_history set status = '$status' , gmt_modified=now() where id='$uuid' ;  "
	sh ../common/src2tgt.datax.sh "$source_querySql" "$target_tableName" "$target_preSql" "$target_postSql" 
}




#  发布任务-检查
fn_pub_check()
{
	local sql="
	SELECT count(1) cnt
	  FROM hera_sync_pub_group A1 
	  LEFT JOIN hera_group B1
	         ON A1.id=B1.id
	      WHERE A1.rs_id='$uuid'
	      AND (A1.name <> B1.name OR A1.owner <> B1.owner OR A1.parent <> B1.parent)
	"
	export MYSQL_PWD=$TARGET_SERVER_PASSWORD
    local re=$($MYSQLT "$sql")
    if [ "$re" = '0' ];then
    	local status='发布-验证通过'
    	sql="update hera_sync_pub_history set status = '$status', gmt_modified=now()  where id='$uuid' ; "
    	$MYSQLT "$sql"
    else  
    	return 1
    fi
}

# 发布-备份数据
fn_pub_backup_data()
{
	local status='发布-备份数据'
	local sql="update hera_sync_pub_history set status = '$status', gmt_modified=now()  where id='$uuid' ;  "
	sql="$sql 
		INSERT INTO hera_sync_pub_job
		SELECT  $META_HERA_JOB_COLUMNS ,  'bak-$uuid' 
		FROM hera_job 
		WHERE id IN ($group_jobs)
		"
	fn_target_exec_sql "$sql"
}


# 发布任务
fn_pub_generate_data()
{
	local status2='发布-完成'
	local sql="select group_concat(name,'(',id,')') as js from hera_job where id in ($group_jobs) "
	local msg2=$($MYSQLT "$sql")
	if [ "$msg2" != "NULL" ];then
		fn_print_info "$status2" "发布任务前，[$group_display]被清理的任务:[$msg2]"
	fi
    sql="  
				delete from hera_job where id IN ($group_jobs); 

				INSERT INTO hera_job
				SELECT  $META_HERA_JOB_COLUMNS
				 from hera_sync_pub_job 
			    where rs_id='$uuid';

			    update hera_job set gmt_modified=now() where id in ($group_jobs); 
	             "
	fn_target_exec_sql "$sql"
	sql=" update hera_sync_pub_history set status = '$status2', gmt_modified=now()  where id='$uuid'; "
	fn_target_exec_sql "$sql"
	fn_source_exec_sql "$sql"
}


######################################################################################
display_usage() 
{
  echo '发布任务组(小目录)[从dev到prod环境]'
  echo "${0}:  usage [-group groupid] [-remark remark_desc]"
  echo  '           -group:  小目录的group_id值'
  echo  '           -remark: 描述' 
  echo  "Example  ${0} -group 10 -remark '说明'"
}

display_para_error() 
{
  echo "Unknown parameters : $1"
  echo ''
  display_usage
  exit -1
}

if [ $# -eq 0 ];then
    display_usage
    exit -1
fi

while [ $# -gt 0 ]; do
  case "$1" in
    -group)
              input_group_id=$2
              shift
              ;;
    -remark)     
              input_name=$2
              shift
              ;;
    *)
        display_para_error "$1"
  esac
  shift       # Check next set of parameters.
done


######################################################################################
# 发布功能main

fn_header_print
pall_flow_display="初验 ----> 发布申请 ----> 传输数据 ----> 检查验证 ----> 备份数据  --> 发布完成"
fn_print_info '发布流程' "$pall_flow_display"


fn_first_check
if [ "$?" = "0" ];then
    fn_print_info '发布-初验' "任务组${group_display}存在"
else  
	fn_print_error '发布-初验' "任务组[${input_group_id}]不存在或非小目录;只支持发布小目录"
fi

status='发布-申请'
fn_prepare_data
if [ "$?" = "0" ];then
    fn_print_info "$status" "任务组${group_display}通过"
else
	error_msg="任务组${group_display}失败"
	status="$status-失败"
	psql="update hera_sync_pub_history set status = '$status', gmt_modified=now(),remark='$error_msg'  where id='$uuid' ; "
	$MYSQLS "$psql"
	fn_print_error "$status" "${error_msg}"
fi

status='发布-传输数据'
fn_pub_transfer_data
if [ "$?" = "0" ];then
    fn_print_info "$status" "任务组${group_display}通过"
else  
	error_msg="任务组${group_display}失败"
	status="$status-失败"
	psql="update hera_sync_pub_history set status = '$status', gmt_modified=now(),remark='$error_msg'  where id='$uuid' ; "
	$MYSQLS "$psql"
	$MYSQLT "$psql"
	fn_print_error "$status" "${error_msg}"
fi


status='发布-检查验证'
fn_pub_check
if [ "$?" = "0" ];then
    fn_print_info "$status" "检查通过(任务组及其父任务组一致！)"
else
	status="$status-失败"  
	psql="SELECT group_concat(A1.name,'(',A1.id,')|',B1.name,'(',B1.id,')') err
		  FROM hera_sync_pub_group A1 
		  LEFT JOIN hera_group B1
         ON A1.id=B1.id
      WHERE A1.rs_id='$uuid'
      AND (A1.name <> B1.name OR A1.owner <> B1.owner OR A1.parent <> B1.parent)"
    echo "$psql"
    error_msg=$($MYSQLT "$psql")
    error_msg="检查不通过:任务组${group_display}下的[$error_msg]任务的名称或Owner或父任务组的值不一样;请先从prod同步任务组到dev环境)"
	psql="update hera_sync_pub_history set status = '$status', gmt_modified=now(),remark='$error_msg'  where id='$uuid' ;"
	$MYSQLS "$psql"
	$MYSQLT "$psql"

	fn_print_error "$status" "$error_msg"
fi

status='发布-备份数据'
fn_pub_backup_data
if [ "$?" = "0" ];then
    fn_print_info "$status" "任务组${group_display}备份通过"
else  
	status="$status-失败"
    error_msg="任务组${group_display}备份失败"
	psql="update hera_sync_pub_history set status = '$status', gmt_modified=now(),remark='$error_msg'  where id='$uuid' ;  "
	$MYSQLT "$psql"
	$MYSQLS "$psql"
	fn_print_error "$status" "${error_msg}"
fi

status='发布-完成'
fn_pub_generate_data
if [ "$?" = "0" ];then
    fn_print_info "$status" "任务组${group_display}下的任务[${group_jobs_display}]发布成功"
else  
	status="$status-失败"
    error_msg="任务组${group_display}下的任务[${group_jobs_display}]发布失败"
	psql="update hera_sync_pub_history set status = '$status', gmt_modified=now(),remark='$error_msg'  where id='$uuid' ;  "
	$MYSQLT "$psql"
	$MYSQLS "$psql"
	fn_print_error "$status" "$error_msg"
fi