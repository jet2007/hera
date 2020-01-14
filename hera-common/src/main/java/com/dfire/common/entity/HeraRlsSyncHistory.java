package com.dfire.common.entity;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Date;

/**
 * @author: jet
 * @time: Created in 2020-01-14
 */
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class HeraRlsSyncHistory {
    private Integer id;
    private String name;
    private String operate_obj;
    private Integer operate_id;
    private String status;
    private Date gmtCreate;
    private Date gmtModified;
    private String remark;
}
