


DROP TABLE if exists hera_sync_pub_history;
CREATE TABLE hera_sync_pub_history (
  id varchar(50) NOT NULL ,
  name varchar(250) CHARACTER SET utf8 COLLATE utf8_general_ci DEFAULT NULL,
  operate_obj varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci DEFAULT NULL,
  operate_id int(11) DEFAULT NULL,
  status varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci DEFAULT NULL,
  gmt_create datetime DEFAULT CURRENT_TIMESTAMP,
  gmt_modified datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  remark varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci DEFAULT NULL,
  PRIMARY KEY (id)
)
ENGINE = INNODB
CHARACTER SET utf8mb4
COLLATE utf8mb4_general_ci;


DROP TABLE if exists hera_sync_pub_group;
CREATE TABLE hera_sync_pub_group (
  id int(11) DEFAULT NULL,
  configs text DEFAULT NULL,
  description varchar(256) DEFAULT NULL,
  directory int(11) NOT NULL,
  gmt_create datetime DEFAULT CURRENT_TIMESTAMP,
  gmt_modified datetime DEFAULT CURRENT_TIMESTAMP,
  name varchar(255) NOT NULL,
  owner varchar(255) NOT NULL,
  parent int(11) DEFAULT NULL,
  resources text DEFAULT NULL,
  existed int(11) NOT NULL DEFAULT 1,
  rs_id varchar(50) DEFAULT NULL
)
ENGINE = INNODB
CHARACTER SET utf8mb4
COLLATE utf8mb4_general_ci;



DROP TABLE if exists hera_sync_pub_job;
CREATE TABLE hera_sync_pub_job (
  id bigint(30) DEFAULT NULL COMMENT '任务id',
  auto tinyint(2) DEFAULT 0 COMMENT '自动调度是否开启',
  configs text DEFAULT NULL COMMENT '配置的环境变量',
  cron_expression varchar(32) DEFAULT NULL COMMENT 'cron表达式',
  cycle varchar(16) DEFAULT NULL COMMENT '是否是循环任务',
  dependencies varchar(2000) DEFAULT NULL COMMENT '依赖的任务id,逗号分隔',
  description varchar(256) DEFAULT NULL COMMENT '任务描述',
  gmt_create datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  gmt_modified datetime DEFAULT CURRENT_TIMESTAMP,
  group_id int(11) NOT NULL COMMENT '所在的目录 id',
  history_id bigint(20) DEFAULT NULL COMMENT '运行历史id',
  host varchar(32) DEFAULT NULL COMMENT '运行服务器ip',
  last_end_time datetime DEFAULT NULL,
  last_result varchar(16) DEFAULT NULL,
  name varchar(256) NOT NULL COMMENT '任务名称',
  offset int(11) DEFAULT NULL,
  owner varchar(256) NOT NULL,
  post_processors varchar(256) DEFAULT NULL COMMENT '任务运行所需的后置处理',
  pre_processors varchar(256) DEFAULT NULL COMMENT '任务运行所需的前置处理',
  ready_dependency varchar(16) DEFAULT NULL COMMENT '任务已完成的依赖',
  resources text DEFAULT NULL COMMENT '上传的资源文件配置',
  run_type varchar(16) DEFAULT NULL COMMENT '运行的job类型(hive,shell)',
  schedule_type tinyint(4) DEFAULT NULL COMMENT '任务调度类型',
  script mediumtext DEFAULT NULL COMMENT '脚本内容',
  start_time datetime DEFAULT NULL,
  start_timestamp bigint(20) DEFAULT NULL,
  statistic_end_time datetime DEFAULT NULL,
  statistic_start_time datetime DEFAULT NULL,
  status varchar(16) DEFAULT NULL,
  timezone varchar(32) DEFAULT NULL,
  host_group_id tinyint(2) DEFAULT NULL COMMENT '分发的执行机器组id',
  must_end_minute int(2) DEFAULT 0,
  area_id varchar(50) DEFAULT '1' COMMENT '区域ID,多个用,分割',
  repeat_run tinyint(2) DEFAULT 0 COMMENT '是否允许任务重复执行',
  is_valid tinyint(1) DEFAULT 1 COMMENT '任务是否删除',
  cron_period varchar(100) DEFAULT NULL,
  cron_interval int(11) DEFAULT NULL,
  biz_label varchar(500) DEFAULT '',
  rs_id varchar(50) DEFAULT NULL
)
ENGINE = INNODB
CHARACTER SET utf8mb4
COLLATE utf8mb4_general_ci
COMMENT = 'hera的job 记录表';