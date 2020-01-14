package com.dfire.common.service.impl;

import com.dfire.common.entity.HeraRlsSyncHistory;
import com.dfire.common.mapper.HeraRlsSyncHistoryMapper;
import com.dfire.common.service.HeraRlsSyncHistoryService;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;


/**
 * @author: jet
 * @time: Created in 2020-01-14
 */
@Service("heraRlsSyncHistoryService")
public class HeraRlsSyncHistoryServiceImpl implements HeraRlsSyncHistoryService {

    @Autowired
    private HeraRlsSyncHistoryMapper heraRlsSyncHistoryMapper;
    
    @Override
	public HeraRlsSyncHistory findById(Integer id) {
		return heraRlsSyncHistoryMapper.findById(id);
	}

	@Override
	public Integer insert(HeraRlsSyncHistory heraRlsSyncHistory) {
		return heraRlsSyncHistoryMapper.insert(heraRlsSyncHistory);
	}

	@Override
	public int update(HeraRlsSyncHistory heraRlsSyncHistory) {
		return heraRlsSyncHistoryMapper.update(heraRlsSyncHistory);
	}
	
	@Override
	public int prepareRlsSyncGroupAndJob(Integer rs_id, String re_status) {
		HeraRlsSyncHistory heraRlsSyncHistory =findById(rs_id);
		
		return 0;
	}


}
