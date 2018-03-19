<%@ page language="java" import="java.util.*" pageEncoding="UTF-8"%>
<%@ taglib uri="/WEB-INF/raqsoftReport.tld" prefix="report" %>
<%
String path = request.getContextPath();
String basePath = request.getScheme()+"://"+request.getServerName()+":"+request.getServerPort()+path+"/";
%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
  <head>
    <base href="<%=basePath%>">
    
    <title>人人聚财账单</title>
	<meta http-equiv="pragma" content="no-cache">
	<meta http-equiv="cache-control" content="no-cache">
	<meta http-equiv="expires" content="0">    
	<meta http-equiv="keywords" content="keyword1,keyword2,keyword3">
	<meta http-equiv="description" content="This is my page">
	<!--
	<link rel="stylesheet" type="text/css" href="styles.css">
	-->
  </head>
  
  <body>
  	<div style="margin-left:60px;">
    <br/><a href="merge.jsp"><b>全部存为Excel</b></a><br/>
    <br/><b>付款汇总：</b>
    <report:html name="fkhz" reportFileName="fkhz.rpx" params="userid=${param.userid}" needSaveAsExcel="yes"></report:html>
    <br/><b>汇总：</b>
    <report:html name="hz" reportFileName="hz.rpx" params="userid=${param.userid}" needSaveAsExcel="yes"></report:html>
    <br/><b>汇总明细：</b>
    <report:html name="hzmx" reportFileName="hzmx.rpx" params="userid=${param.userid}" needSaveAsExcel="yes"></report:html>
    <br/><br/><b>社保参保明细：</b>
    <report:html name="sbmx" reportFileName="sbmx.rpx" params="userid=${param.userid}" needSaveAsExcel="yes"></report:html>
    <br/><br/><b>公积金参保明细：</b>
    <report:html name="gjjmx" reportFileName="gjjmx.rpx" params="userid=${param.userid}" needSaveAsExcel="yes"></report:html>
    </div>
  </body>
</html>
