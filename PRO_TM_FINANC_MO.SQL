CREATE PROCEDURE ETL.PRO_TM_FINANC_MO (IN vYearMonth INTEGER,IN vReRunIndex INTEGER,OUT vRetCode INTEGER )
    LANGUAGE SQL
-------------------------------------------------------------------------------
--  SQL 存储过程
-------------------------------------------------------------------------------
--  Purpose :  DM_MIS月报汇总表
--  Auther: 闫鑫
--  Date : 2012-7-9
--  Modified History:
--  ---------------------------------------------------------------------------
--  DATE         AUTHOR   VERSION         DESCRIPTION
--  2012-07-09   闫鑫     V01.00.000      根据DSS-Pac-1207-023新建存储过程
--  2012-09-07   闫鑫     V01.00.001      根据DSS-Def-1209-024增加Step 0中删除目标表条件排除延迟数据
--  2014-06-18   林佳耀   V01.00.002      根据DSS-ReqChange-1406-034，MIS提速优化改造第二期，增加增加汇总源表DM.TM_FINANC_CNSM_M
--  2015-03-16   林佳耀   V01.00.003      根据2015年定报，增加汇总源表DM.TM_FINANC_MO_ZGPRS
--  2015-05-18   曾宪雄   V01.00.004      根据改进_SR201412300005011_5月上报改进,修改指标DA4105的出数逻辑
--  2016-01-26   张俊     V01.00.005      根据SR201512290009001 增加汇总源表DM.TM_FINANC_MO_VOLTE
--  2016-11-16   黄创辉   V01.00.006      根据需求 SR201610310013001 补充汇总物联网数据
--  2017-03-01   张  俊   V01.00.006      根据需求 BR201702270010 增加地市字段
--  2017-07-28   黄创辉   V01.00.007      增加存储数据PRO_TM_FINANC_MO_JFQD
--  ---------------------------------------------------------------------------
--  Current Version : V01.00.007
--  输入参数
--  vYearMonth 统计月份  格式 YYYYMM
--  vReRunIndex :0代表是重跑.其他是正常跑.
-------------------------------------------------------------------------------
P1: BEGIN
  -- 日志变量
  DECLARE SQLCODE integer default 0;
  DECLARE vSqlCode varchar(20);
  DECLARE vProcStep VARCHAR(32);  -- 出错点（写错误日志时用）
  DECLARE vMsgText  VARCHAR(256); -- 错误描述（写错误日志时用）
  DECLARE vCount    INTEGER;      -- （写错误日志时用）
  DECLARE vJobName  VARCHAR(200);  -- 作业名称（写错误日志时用）
  DECLARE vEventDesc VARCHAR(512); -- （写错误日志时用）
  DECLARE vRowCount INTEGER;
  -- 程序变量
  DECLARE vSqlText VARCHAR(32600);
  DECLARE target_table_name varchar(50);
  DECLARE procname varchar(64);      --存储过程名
  DECLARE target_line varchar(128);  --列名
  --声明出错处理
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    GET DIAGNOSTICS EXCEPTION 1 vMsgText = MESSAGE_TEXT;
    SET vSqlCode='SQLCODE'||char(SQLCODE);
    ROLLBACK;
    SET vRetCode=1;
    SET vEventDesc = vJobName ||  '运行错误：' || vMsgText;
    CALL ETL.INSERT_EVENT_LOG(vReRunIndex,vSqlCode, vEventDesc,0,0,0,vProcStep,0) ;
  END;

  -- 变量初始化
  SET vRetCode = 0;
  SET vJobName = ' DM_MIS月报汇总表';
  SET vJobName = vJobName || '('||CHAR(vYearMonth)||',?)';
  SET vEventDesc = '';
  SET target_table_name = 'DM.TM_FINANC_MO ';
  SET procname = 'PRO_TM_FINANC_MO';
  SET target_line = 'current timestamp,'||procname||'';

   -- 程序开始
  CALL ETL.INSERT_EVENT_LOG(vReRunIndex,'开始计算',vJobName || '开始运行',0,0,0,vProcStep,0) ;

  -- Step 0
  SET vProcStep = 'Step 0';

  IF vReRunIndex = 0
  THEN
    SET vProcStep = 'Step 0';
    SET vSqlText = 'DELETE FROM '||target_table_name||' WHERE TM_INTRVL_CD = '||CHAR(vYearMonth)||' AND PROCNAME <> ''PRO_TM_FINANC_MO_SP_DELAY'' ';
    PREPARE s1 FROM vSqlText;
         EXECUTE s1;
  END IF;

  -- Step  1: 数据汇总
  -- 修改说明: 2012/7/9  闫鑫   DSS-Def-1207-027 新增
  -- 修改说明: 2017/3/1  张俊   新增分地市字段
  --           2017/7/26 黄创辉 TM_FINANC_MO_BASI 增加条件限制
  SET vProcStep = 'Step 1';
  SET vEventDesc = vEventDesc ||vProcStep||':'||CHAR(current time)||';';
  SET vSqlText = ''
  ||'INSERT INTO '||target_table_name||'(TM_INTRVL_CD, CMCC_BRANCH_CD,TARGET_CD, VALUE, CREATE_TIM, PROCNAME) '
  ||'SELECT TM_INTRVL_CD ,CMCC_BRANCH_CD, TARGET_CD ,VALUE ,CREATE_TIM ,PROCNAME '
  ||'FROM DM.TM_FINANC_MO_BUSI '
  ||'WHERE TM_INTRVL_CD='||CHAR(vYearMonth)||' AND PROCNAME NOT IN(''PRO_TM_FINANC_MO_BUSI_SED'')   ' 
  ||'UNION ALL '
  ||'SELECT TM_INTRVL_CD ,CMCC_BRANCH_CD, TARGET_CD ,VALUE ,CREATE_TIM ,PROCNAME '
  ||'FROM DM.TM_FINANC_MO_SP '
  ||'WHERE TM_INTRVL_CD='||CHAR(vYearMonth)||' AND PROCNAME IN(''PRO_TM_FINANC_MO_SP'') '
  ||'UNION ALL '
  ||'SELECT TM_INTRVL_CD ,CMCC_BRANCH_CD, TARGET_CD ,VALUE ,CREATE_TIM ,PROCNAME '
  ||'FROM DM.TM_FINANC_MO_FUNC '
  ||'WHERE TM_INTRVL_CD='||CHAR(vYearMonth)||'  '
  ||'UNION ALL '
  ||'SELECT TM_INTRVL_CD ,CMCC_BRANCH_CD, TARGET_CD ,VALUE ,CREATE_TIM ,PROCNAME '
  ||'FROM DM.TM_FINANC_MO_BASI '
  ||'WHERE TM_INTRVL_CD='||CHAR(vYearMonth)||' AND (PROCNAME=''PRO_TM_FINANC_MO_BASI'' OR (PROCNAME=''PRO_TM_FINANC_MO_JFQD'' AND TARGET_CD=''DS3101'')) '
  ||'UNION ALL '
  ||'SELECT TM_INTRVL_CD ,CMCC_BRANCH_CD, TARGET_CD ,VALUE ,CREATE_TIM ,PROCNAME '
  ||'FROM DM.TM_FINANC_MO_TD '
  ||'WHERE TM_INTRVL_CD='||CHAR(vYearMonth)||'  '
  --20140618 linjiayao 增加汇总源表DM.TM_FINANC_CNSM_M
  ||'UNION ALL '
  ||'SELECT STAT_MO ,CMCC_BRANCH_CD, TARGET_CD ,VALUE ,CREATE_TIM ,PROCNAME '
  ||'FROM DM.TM_FINANC_CNSM_M '
  ||'WHERE STAT_MO='||CHAR(vYearMonth)||' '
  --20150316 linjiayao 增加二次迁移到一次的存储指标
  ||'UNION ALL '
  ||'SELECT TM_INTRVL_CD ,CMCC_BRANCH_CD, TARGET_CD ,VALUE ,CREATE_TIM ,PROCNAME '
  ||'FROM DM.TM_FINANC_MO_ZGPRS '
  ||'WHERE TM_INTRVL_CD='||CHAR(vYearMonth)||' '
  --20160126 zhngjun 增加Volte指标的存储
  --20170301 下线RPO_TM_FINANC_MO_VOLTE
  ||'UNION ALL '
  ||'SELECT TM_INTRVL_CD ,CMCC_BRANCH_CD, TARGET_CD ,VALUE ,CREATE_TIM ,PROCNAME '
  ||'FROM DM.TM_FINANC_MO_VOLTE '
  ||'WHERE TM_INTRVL_CD='||CHAR(vYearMonth)||' AND PROCNAME=''PRO_TM_FINANC_MO_IOT''  '    
  ||' ';
 PREPARE S1 FROM vSqlText;
 EXECUTE S1;

SET vEventDesc=vJobName || vEventDesc;

END P1