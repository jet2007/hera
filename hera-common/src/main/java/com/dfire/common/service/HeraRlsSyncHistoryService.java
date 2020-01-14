package com.dfire.common.service;

import com.dfire.common.entity.HeraRlsSyncHistory;


/**
 * @author: jet
 * @time: Created in 2020-01-14
 * @desc
 */
public interface HeraRlsSyncHistoryService {

	HeraRlsSyncHistory findById(Integer id );

    Integer insert(HeraRlsSyncHistory heraRlsSyncHistory);

    int update(HeraRlsSyncHistory heraRlsSyncHistory);
    
    int prepareRlsSyncGroupAndJob(Integer rs_id,String re_status);

}
