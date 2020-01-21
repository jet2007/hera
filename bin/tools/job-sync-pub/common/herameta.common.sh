#!/bin/bash


# source服务器的查找父目录的列表
fn_source_get_group_parents()
{
    local re=$1
    local sql
    local parent_group
    local id=$1
    export MYSQL_PWD=$SOURCE_SERVER_PASSWORD
    while [[ "$id" != "" ]]; do
        parent_group=''
        sql="select parent from hera_group where id=$id"
        parent_group=$($MYSQLS "$sql")
        if [ "$parent_group" = '' ];then
            id=""
        elif [ "$parent_group" = '0' ];then
            id=""
        else  
            id=$parent_group
            if [ "$re" = '' ];then
                re="$parent_group"
            else  
                re="$re,$parent_group"
            fi
        fi
    done
    echo $re
}




# target服务器的查找父目录的列表
fn_target_get_group_parents()
{
    local re=$1
    local sql
    local parent_group
    local id=$1
    export MYSQL_PWD=$TARGET_SERVER_PASSWORD
    while [[ "$id" != "" ]]; do
        parent_group=''
        sql="select parent from hera_group where id=$id"
        parent_group=$($MYSQLT "$sql")
        if [ "$parent_group" = '' ];then
            id=""
        elif [ "$parent_group" = '0' ];then
            id=""
        else  
            id=$parent_group
            if [ "$re" = '' ];then
                re="$parent_group"
            else  
                re="$re,$parent_group"
            fi
        fi
    done
    echo $re
}


# target服务器的查找子目录的列表,不包括自己
fn_target_get_group_children()
{
    local re=''
    local sql
    local children
    local id=$1
    export MYSQL_PWD=$TARGET_SERVER_PASSWORD
    while [[ "$id" != "" ]]; do
        children=''
        sql="select group_concat(id) from hera_group where parent in ($id ) "
        children=$($MYSQLT "$sql")
        if [ "$children" = '' ];then
            id=""
        elif [ "$children" = 'NULL' ];then
            id=""
        else  
            id=$children
            if [ "$re" = '' ];then
                re="$children"
            else  
                re="$re,$children"
            fi
        fi
    done
    echo $re
}



# target服务器的查找目录下的jobs列表
fn_target_get_jobs_in_group()
{
    local group_id=$1
    local sql="select GROUP_CONCAT(id) as jobs from hera_job where group_id in ($group_id)"
    export MYSQL_PWD=$TARGET_SERVER_PASSWORD
    local jobs=$($MYSQLT "$sql")
    if [ "$jobs" = 'NULL' ];then
        jobs=""
    fi
    echo $jobs
}


# target服务器的查找目录下的jobs列表
fn_source_get_jobs_in_group()
{
    local group_id=$1
    local sql="select GROUP_CONCAT(id) as jobs from hera_job where group_id in ($group_id) "
    export MYSQL_PWD=$SOURCE_SERVER_PASSWORD
    local jobs=$($MYSQLS "$sql")
    if [ "$jobs" = 'NULL' ];then
        jobs=""
    fi
    echo $jobs
}


# source服务器的查找目录下的jobs列表
fn_source_get_jobs_display_in_group()
{
    local group_id=$1
    local sql="select GROUP_CONCAT( concat(name,'(',id,')') ) as jobs from hera_job where group_id in ($group_id) "
    export MYSQL_PWD=$SOURCE_SERVER_PASSWORD
    local jobs=$($MYSQLS "$sql")
    if [ "$jobs" = 'NULL' ];then
        jobs=""
    fi
    echo $jobs
}


# source服务器的查找目录下的jobs列表
fn_target_get_jobs_display_in_group()
{
    local group_id=$1
    local sql="select GROUP_CONCAT( concat(name,'(',id,')') ) as jobs from hera_job where group_id in ($group_id) "
    export MYSQL_PWD=$TARGET_SERVER_PASSWORD
    local jobs=$($MYSQLT "$sql")
    if [ "$jobs" = 'NULL' ];then
        jobs=""
    fi
    echo $jobs
}


# source服务器的查找目录下的jobs列表
fn_source_get_group_display_by_id()
{
    local group_id=$1
    local sql="select GROUP_CONCAT(name,'(',id,')')  as jobs from hera_group where id in ( $group_id ) "
    export MYSQL_PWD=$SOURCE_SERVER_PASSWORD
    local jobs=$($MYSQLS "$sql")
    if [ "$jobs" = 'NULL' ];then
        jobs=""
    fi
    echo $jobs
}


# target服务器的查找目录下的jobs列表
fn_target_get_group_display_by_id()
{
    local group_id=$1
    local sql="select GROUP_CONCAT(name,'(',id,')')  as jobs from hera_group where id in ( $group_id ) "
    export MYSQL_PWD=$SOURCE_SERVER_PASSWORD
    local jobs=$($MYSQLS "$sql")
    if [ "$jobs" = 'NULL' ];then
        jobs=""
    fi
    echo $jobs
}


# source服务器执行sql
fn_source_exec_sql()
{
    export MYSQL_PWD=$SOURCE_SERVER_PASSWORD
    $MYSQLS "$1"
}

# target服务器执行sql
fn_target_exec_sql()
{
    export MYSQL_PWD=$TARGET_SERVER_PASSWORD
    $MYSQLT "$1"
}


# source服务器query写入到文件
fn_source_querysql2file()
{
    export MYSQL_PWD=$SOURCE_SERVER_PASSWORD
    $MYSQLS "$1" > $2
}

# source服务器query写入到文件
fn_target_querysql2file()
{
    export MYSQL_PWD=$TARGET_SERVER_PASSWORD
    $MYSQLT "$1" > $2
}

