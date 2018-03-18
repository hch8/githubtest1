CREATE PROCEDURE PROC_GJJMX_DATA (IN userid VARCHAR(50)) LANGUAGE SQL
BEGIN
	DECLARE oUserDeptId varchar(500);
	DECLARE oFstDeptTmp varchar(500);
  DECLARE oFstDeptId varchar(500);
  DECLARE oAreaCnt INTEGER;
  DECLARE vArg INTEGER;
  DECLARE oAreaId varchar(50);
  DECLARE oAreaName varchar(50);
  DECLARE oChildIds varchar(500);
  
	DECLARE oTempChild VARCHAR(4000);
  DECLARE oTemp VARCHAR(4000);
  
  #---------程序开始----------------
  # Step 1 获取用户的部门ID
  select group_concat(orgnize.id) into oUserDeptId
	from vip_common_dev.sb_sys_user suser 
	join t_common_orgnize_user_responsibility uo on uo.user_id=suser.id
	join t_common_orgnize orgnize on uo.orgnize_id=orgnize.id 
	where suser.id=userid;
  
  # Step2 获取最顶级部门的ID
  set oFstDeptTmp = oUserDeptId;
  while oFstDeptTmp is not null
  do
    set oFstDeptId = oFstDeptTmp;
  	select group_concat(orgnize.parent_id) into oFstDeptTmp from t_common_orgnize orgnize where FIND_IN_SET(id,oFstDeptTmp)>0;
  end while;
  
  # Step 3 获取所有区域的ID和名称,插入临时表
  drop table if exists area_tmp_table;
  create temporary table if not exists area_tmp_table (
		id varchar(50) primary key,
		area_name varchar(50)
	);
	
	insert into area_tmp_table 
	select orgnize.id,orgnize.name 
	from t_common_orgnize porgnize 
  join t_common_orgnize orgnize on orgnize.parent_id=porgnize.id
  where FIND_IN_SET(porgnize.id,oFstDeptId)>0;
  
  # Step 4 查询每个区域的子部门，插入临时表
  drop table if exists dept_tmp_table;
  create temporary table if not exists dept_tmp_table (
		id varchar(50) primary key,
		area_name varchar(50)
	);
	
	insert into dept_tmp_table select id,area_name from area_tmp_table;
	
	select count(id) into oAreaCnt from area_tmp_table;
	
	set vArg = 0;
	while vArg < oAreaCnt
	do 
		select id,area_name into oAreaId,oAreaName from area_tmp_table order by id limit vArg,1;
		set oChildIds = oAreaId;
		while oChildIds is not null
		do
			insert into dept_tmp_table select id,oAreaName from t_common_orgnize where FIND_IN_SET(parent_id,oChildIds)>0;
			select group_concat(id) into oChildIds from t_common_orgnize where FIND_IN_SET(parent_id,oChildIds)>0;
		end while;
		set vArg = vArg+1;
  end while;
	
  # Step 5 获取用户所在部门的所有子部门
  select GROUP_CONCAT(orgnize.id) into oTempChild
	from vip_common_dev.sb_sys_user suser 
	join t_common_orgnize_user_responsibility uo on uo.user_id=suser.id
	join t_common_orgnize orgnize on uo.orgnize_id=orgnize.id 
	where suser.id=userid;

	SET oTemp = oTempChild;
  
  WHILE oTempChild IS NOT NULL
  DO
	  SET oTemp = CONCAT(oTemp,',',oTempChild);
	  SELECT GROUP_CONCAT(id) INTO oTempChild FROM t_common_orgnize WHERE FIND_IN_SET(parent_id,oTempChild) > 0;
  END WHILE;
  
  # Step 6 获取最终数据
  select 
    empInfo.job_num as 参保人工号,
    concat(substr(accfundBase.fy_date,1,4),substr(accfundBase.fy_date,6,2)) as 参保月份,
    areatmp.area_name as 区域,
    orgnize.name as 门店,
    '' as 主体简称,
    empBase.name as 参保人,
    empBase.id_card as 身份证号,
    accfundSure.account as 公积金号,
    accfundBase.insurance_address_name as 参保地,
    itemA.company_base AS 公积金单位缴费基数,
    itemA.company_ratio AS 公积金单位缴费比例,
    itemA.company_amount AS 公积金单位缴费金额,
    itemA.personal_base AS 公积金个人缴费基数,
    itemA.personal_ratio AS 公积金个人缴费比例,
    itemA.personal_amount AS 公积金个人缴费金额,
    accfundBase.company_amount as 企业总金额,
    accfundBase.personal_amount as 个人总金额,
    accfundBase.total_amount as 合计总金额 
  from t_emp_base empBase 
  join t_settlement_bill bill on bill.name='深圳前海新煤电子商务有限公司_2018-03_结算单 0183'
  join t_settlement_bill_accfund accfundBase on accfundBase.employee_id=empBase.id and accfundBase.settle_id=bill.id
  LEFT JOIN t_settlement_bill_accfund_items itemA ON accfundBase.id=itemA.settlement_bill_pro_id
  left join t_emp_info empInfo on empInfo.emp_id=empBase.id
  left join t_emp_comp_history ech on ech.emp_id=empBase.id
  left join t_common_orgnize orgnize on orgnize.id=ech.dept_id
  left join dept_tmp_table areatmp on areatmp.id=orgnize.id
  LEFT JOIN (select employee_id,max(account) as account from t_welfare_emp_accfund_sure group by employee_id) accfundSure on accfundSure.employee_id=empBase.id
  where FIND_IN_SET(orgnize.id,oTemp) > 0 ;
	
END



