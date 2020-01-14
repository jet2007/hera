package com.dfire.common.mapper;

import com.dfire.common.entity.HeraRlsSyncHistory;
import com.dfire.common.mybatis.HeraInsertLangDriver;
import com.dfire.common.mybatis.HeraSelectLangDriver;
import com.dfire.common.mybatis.HeraUpdateLangDriver;
import org.apache.ibatis.annotations.*;


/**
 * @author: jet
 * @time: Created in 2020-01-14
 * @desc
 */
public interface HeraRlsSyncHistoryMapper {

    @Select("select * from hera_rls_sync_history where id = #{id}")
    @Lang(HeraSelectLangDriver.class)
    HeraRlsSyncHistory findById(Integer id);

    @Insert("insert into hera_rls_sync_history (#{heraRlsSyncHistory})")
    @Lang(HeraInsertLangDriver.class)
    @Options(useGeneratedKeys = true, keyProperty = "id", keyColumn = "id")
    Integer insert(HeraRlsSyncHistory heraRlsSyncHistory);


    @Update("update hera_rls_sync_history (#{heraRlsSyncHistory}) where id = #{id}")
    @Lang(HeraUpdateLangDriver.class)
    int update(HeraRlsSyncHistory heraRlsSyncHistory);

}

