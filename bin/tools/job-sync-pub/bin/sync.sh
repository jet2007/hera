#!/bin/bash

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
parent_groups='' # 自目录及父目录
children_groups=''  # 自目录及子目录
children_group_jobs_id=''    # 自目录及子目录下的所有任务
children_group_jobs_display='' # 自目录及子目录下的所有任务
group_display=''
all_groups_id='' #  自目录及父目录+子目录
all_groups_display='' #  自目录及父目录+子目录
input_group_id='' #入参1 
input_name='' #入参2
input_sync_type='' #入参3
input_group_dir='小目录' #1=小目录,0=大目录
input_group_dir_id=1 #1=小目录,0=大目录

# 输入的目录是否存在,允许大小目录
fn_sync_first_check()
{
	local sql="
	SELECT COUNT(1) CNT
	  FROM hera_group
	      WHERE id=$input_group_id
	"
	export MYSQL_PWD=$TARGET_SERVER_PASSWORD
    local re=$($MYSQLT "$sql")
	if [ "$re" = '0' ];then
	    return 1
	fi

	sql="SELECT case when directory=1 then '小目录' else '大目录' end from hera_group  WHERE id=$input_group_id "
	input_group_dir=$($MYSQLT "$sql")
	group_display=$(fn_target_get_group_display_by_id "$input_group_id")
	parent_groups=$(fn_target_get_group_parents "$input_group_id")
	local children_groups2=$(fn_target_get_group_children "$input_group_id")
	 
	if [ "$children_groups2" = '' ];then
	    children_groups=$input_group_id
	    all_groups_id=$parent_groups
	else
		children_groups="$input_group_id,$children_groups2"
		all_groups_id="$parent_groups,$children_groups2"
	fi
	children_group_jobs_id=$(fn_target_get_jobs_in_group "$children_groups") 
	children_group_jobs_display=$(fn_target_get_jobs_display_in_group "$children_groups")
	all_groups_display=$(fn_target_get_group_display_by_id "$all_groups_id")
}


#同步任务时，准备数据
fn_sync_prepare_data()
{
	local operate_obj=$input_group_dir #当前只支持小目录
	local operate_id=$input_group_id
	local name=$input_name
	local status="同步-申请" 
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
	sql="$sql 
		INSERT INTO hera_sync_pub_group 
		SELECT $META_HERA_GROUP_COLUMNS , '$uuid'
		FROM hera_group 
		where id in ($all_groups_id) ;
	"
	sql="$sql
		INSERT INTO hera_sync_pub_job
		SELECT  $META_HERA_JOB_COLUMNS ,  '$uuid'
		FROM hera_job 
		WHERE id IN ($children_group_jobs_id)
	"
	fn_target_exec_sql "$sql"
}

#  同步任务，传输数据
fn_sync_transfer_data()
{

	local target_querySql="SELECT * FROM hera_sync_pub_history where id='$uuid' "
	local target_tableName="hera_sync_pub_history"
	local target_preSql="SELECT 1;"
	local target_postSql="SELECT 1;"
	sh ../common/tgt2src.datax.sh "$target_querySql" "$target_tableName" "$target_preSql" "$target_postSql" 

	target_querySql="SELECT * FROM hera_sync_pub_group where rs_id='$uuid' "
	target_tableName="hera_sync_pub_group"
	target_preSql="SELECT 1;"
	target_postSql="SELECT 1;"
	sh ../common/tgt2src.datax.sh "$target_querySql" "$target_tableName" "$target_preSql" "$target_postSql" 

	local status='同步-传输数据'
	target_querySql="SELECT * FROM hera_sync_pub_job where rs_id='$uuid' "
	target_tableName="hera_sync_pub_job"
	target_preSql="SELECT 1;"
	target_postSql="update hera_sync_pub_history set status = '$status' , gmt_modified=now() where id='$uuid' ; "
	sh ../common/tgt2src.datax.sh "$target_querySql" "$target_tableName" "$target_preSql" "$target_postSql" 
}




# 同步之前-备份数据
fn_sync_backup_data()
{
	local status='同步-备份数据'
	local sql="update hera_sync_pub_history set status = '$status', gmt_modified=now()  where id='$uuid' ;   

				INSERT INTO hera_sync_pub_group 
				SELECT $META_HERA_GROUP_COLUMNS , 'bak-$uuid' 
				FROM hera_group 
				where id in ($all_groups_id) ;

				INSERT INTO hera_sync_pub_job
				SELECT  $META_HERA_JOB_COLUMNS ,  'bak-$uuid'  
				FROM hera_job 
				WHERE id IN ($children_group_jobs_id) ;
		"
	# 备份数据，则hera_sync_pub_group和hera_sync_pub_job有2份uuid的数据
	fn_source_exec_sql "$sql"

}


# 同步任务
fn_sync_generate_data()
{
	local status1='同步-完成'
	local sql=''
	if [ "$input_sync_type" = "dir" ];then #只同步目录结构
		sql=" delete from hera_group where id in ($all_groups_id); 
				INSERT INTO hera_group 
					SELECT $META_HERA_GROUP_COLUMNS
					  from hera_sync_pub_group 
					 where rs_id='$uuid' ;
			    update hera_group set gmt_modified=now() where id in ($all_groups_id); 
	             "
	    fn_source_exec_sql "$sql"
	    fn_print_info "$status1" "同步目录结构[$all_groups_display]"
	    sql=" update hera_sync_pub_history set status = '$status1', gmt_modified=now()  where id='$uuid'; "
		fn_source_exec_sql "$sql"
		fn_source_exec_sql "$sql"
	elif [ "$input_sync_type" = "all" ];then #只同步目录结构  
		sql=" delete from hera_group where id in ($all_groups_id); 
				delete from hera_job where group_id IN ($children_groups) or id in ( $children_group_jobs_id ) ; 
				INSERT INTO hera_group 
					SELECT $META_HERA_GROUP_COLUMNS
					  from hera_sync_pub_group 
					 where rs_id='$uuid' ;
				INSERT INTO hera_job 
				SELECT  $META_HERA_JOB_COLUMNS
				 from hera_sync_pub_job 
			    where rs_id='$uuid';
			    update hera_group set gmt_modified=now() where id in ($all_groups_id); 
			    update hera_job set gmt_modified=now() where group_id IN ($children_groups); 
	             "
	    fn_source_exec_sql "$sql"
	    fn_print_info "$status1" "同步目录结构+任务:[$all_groups_display],[$children_group_jobs_display]"
	    sql=" update hera_sync_pub_history set status = '$status1', gmt_modified=now()  where id='$uuid'; "
		fn_source_exec_sql "$sql"
		fn_source_exec_sql "$sql"
	fi
}




######################################################################################
display_usage() 
{
  echo '同步任务组[从prod到dev环境]'
  echo "${0}:  usage [-group groupid] [-remark remark_desc]"
  echo  '           -group:  目录的group_id值；支持大小目录'
  echo  '           -type: dir(只同步目录结构),all(目录结构+任务)' 
  echo  '           -remark: 描述' 
  echo  "Example  ${0} -group 10 -type 'dir' -remark '说明'"
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




# parse all the arguments.
while [ $# -gt 0 ]; do    # Until you run out of parameters . . .
  case "$1" in
    -group)
              input_group_id=$2
              shift
              ;;
    -type)
              input_sync_type=$2
			  if  [[ $input_sync_type != 'dir' ]] && [[ $input_sync_type != 'all' ]];then
 				  display_para_error "$1"
			  fi
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




fn_header_print
pall_flow_display="初验 ----> 同步申请 ----> 传输数据 ----> 备份数据  --> 同步完成"
fn_print_info '同步流程' "$pall_flow_display"


fn_sync_first_check 
if [ "$?" = "0" ];then
    fn_print_info '同步-初验' "任务组${group_display}存在"
else  
	fn_print_error '同步-初验' "任务组[${input_group_id}]不存在;支持同步大小目录"
fi


status='同步-申请'
fn_sync_prepare_data
if [ "$?" = "0" ];then
    fn_print_info "$status" "任务组${group_display}通过"
else
	error_msg="任务组${group_display}失败"
	status="$status-失败"
	psql="update hera_sync_pub_history set status = '$status', gmt_modified=now(),remark='$error_msg'  where id='$uuid' ; "
	$MYSQLT "$psql"
	fn_print_error "$status" "${error_msg}"
fi

status='同步-传输数据'
fn_sync_transfer_data
if [ "$?" = "0" ];then
    fn_print_info "$status" "任务组${all_groups_display}通过"
else  
	error_msg="任务组${all_groups_display}失败"
	status="$status-失败"
	psql="update hera_sync_pub_history set status = '$status', gmt_modified=now(),remark='$error_msg'  where id='$uuid' ; "
	$MYSQLS "$psql"
	$MYSQLT "$psql"
	fn_print_error "$status" "${error_msg}"
fi


status='同步-备份数据'
fn_sync_backup_data
if [ "$?" = "0" ];then
    fn_print_info "$status" "任务组${all_groups_display}备份通过"
else  
	status="$status-失败"
    error_msg="任务组${all_groups_display}备份失败"
	psql="update hera_sync_pub_history set status = '$status', gmt_modified=now(),remark='$error_msg'  where id='$uuid' ;  "
	$MYSQLT "$psql"
	$MYSQLS "$psql"
	fn_print_error "$status" "${error_msg}"
fi


status='同步-完成'
if [ "$input_sync_type" = "dir" ];then
    msg="任务组${all_groups_display}同步"
else 
	msg="任务组${all_groups_display}及任务[${children_group_jobs_display}]同步" 
fi
fn_sync_generate_data
if [ "$?" = "0" ];then
	fn_print_info "$status" "${msg}成功" 
else  
	status="$status-失败"
    error_msg="${msg}失败"
	psql="update hera_sync_pub_history set status = '$status', gmt_modified=now(),remark='$error_msg'  where id='$uuid' ;  "
	$MYSQLT "$psql"
	$MYSQLS "$psql"
	fn_print_error "$status" "$error_msg"
fi