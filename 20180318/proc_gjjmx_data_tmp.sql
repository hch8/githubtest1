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
  
  #---------����ʼ----------------
  # Step 1 ��ȡ�û��Ĳ���ID
  select group_concat(orgnize.id) into oUserDeptId
	from vip_common_dev.sb_sys_user suser 
	join t_common_orgnize_user_responsibility uo on uo.user_id=suser.id
	join t_common_orgnize orgnize on uo.orgnize_id=orgnize.id 
	where suser.id=userid;
  
  # Step2 ��ȡ������ŵ�ID
  set oFstDeptTmp = oUserDeptId;
  while oFstDeptTmp is not null
  do
    set oFstDeptId = oFstDeptTmp;
  	select group_concat(orgnize.parent_id) into oFstDeptTmp from t_common_orgnize orgnize where FIND_IN_SET(id,oFstDeptTmp)>0;
  end while;
  
  # Step 3 ��ȡ���������ID������,������ʱ��
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
  
  # Step 4 ��ѯÿ��������Ӳ��ţ�������ʱ��
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
	
  # Step 5 ��ȡ�û����ڲ��ŵ������Ӳ���
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
  
  # Step 6 ��ȡ��������
  select 
    empInfo.job_num as �α��˹���,
    concat(substr(accfundBase.fy_date,1,4),substr(accfundBase.fy_date,6,2)) as �α��·�,
    areatmp.area_name as ����,
    orgnize.name as �ŵ�,
    '' as ������,
    empBase.name as �α���,
    empBase.id_card as ���֤��,
    accfundSure.account as �������,
    accfundBase.insurance_address_name as �α���,
    itemA.company_base AS ������λ�ɷѻ���,
    itemA.company_ratio AS ������λ�ɷѱ���,
    itemA.company_amount AS ������λ�ɷѽ��,
    itemA.personal_base AS ��������˽ɷѻ���,
    itemA.personal_ratio AS ��������˽ɷѱ���,
    itemA.personal_amount AS ��������˽ɷѽ��,
    accfundBase.company_amount as ��ҵ�ܽ��,
    accfundBase.personal_amount as �����ܽ��,
    accfundBase.total_amount as �ϼ��ܽ�� 
  from t_emp_base empBase 
  join t_settlement_bill bill on bill.name='����ǰ����ú�����������޹�˾_2018-03_���㵥 0183'
  join t_settlement_bill_accfund accfundBase on accfundBase.employee_id=empBase.id and accfundBase.settle_id=bill.id
  LEFT JOIN t_settlement_bill_accfund_items itemA ON accfundBase.id=itemA.settlement_bill_pro_id
  left join t_emp_info empInfo on empInfo.emp_id=empBase.id
  left join t_emp_comp_history ech on ech.emp_id=empBase.id
  left join t_common_orgnize orgnize on orgnize.id=ech.dept_id
  left join dept_tmp_table areatmp on areatmp.id=orgnize.id
  LEFT JOIN (select employee_id,max(account) as account from t_welfare_emp_accfund_sure group by employee_id) accfundSure on accfundSure.employee_id=empBase.id
  where FIND_IN_SET(orgnize.id,oTemp) > 0 ;
	
END



