#!/usr/bin/env python
# -*- coding:utf-8 -*-
import MySQLdb
import simplejson as json
import os,sys
#import chardet
#接收人员,RTX标识id 使用','分隔
#recevier = '1192,1063,1189'
recevier = '1192'

#获取oss mysql中的相关主机信息
host = '10.10.41.2'
user = 'root'
password = 'test'
database = 'jd_oss'
sql = "select * from machine where machine_platform='Ucloud'"
func = []
db = MySQLdb.connect(host,user,password,database,charset='utf8')
cur = db.cursor(cursorclass=MySQLdb.cursors.DictCursor)
cur.execute(sql)
mysql_result = cur.fetchall()
cur.close()
db.close()
#获取描述字段,将会以描述为索引进行判断
func.append([h['machine_func'] for h in mysql_result])

#通过api获取ucloud信息
jsonobject = json.load(os.popen('python /data/tools/ucloud_sdk/python-sdk-v2-master/describe_uhost_instance.py'))

for host in range(0,len(jsonobject["UHostSet"])):
	host_info = jsonobject["UHostSet"][host]["IPSet"]
	remark = jsonobject["UHostSet"][host]["Remark"]
	print '\033[31m ** %s **\033[0m \n对比开始....' % remark.encode('utf-8')
	#获取json格式的Ucloud相关ip信息,如果对于字段不存在,则以空字符赋值
	try:
		ucloud_private_ip = jsonobject["UHostSet"][host]["IPSet"][0]['IP']
	except IndexError:
		ucloud_private_ip = ''
	try:
		ucloud_unicom_ip = jsonobject["UHostSet"][host]["IPSet"][1]['IP']
	except IndexError:
		ucloud_unicom_ip = ''
	try:
		ucloud_telecom_ip = jsonobject["UHostSet"][host]["IPSet"][2]['IP']
	except IndexError:
		ucloud_telecom_ip = ''

	#获取mysql对应主机信息
	for oss_host in range(len(func[0])):
		res = func[0][oss_host]
		if remark in res:
			oss_private_ip = mysql_result[oss_host]['machine_localip']
			oss_unicom_ip = mysql_result[oss_host]['machine_cncip']
			oss_telecom_ip = mysql_result[oss_host]['machine_telip']

			if  cmp(ucloud_private_ip,oss_private_ip) or cmp(ucloud_unicom_ip,oss_unicom_ip) or cmp(ucloud_telecom_ip,oss_telecom_ip):
				error =   '''%s : oss和ucloud ip数据不一致!请检查..注意电信和网通ip的顺序\nUcloud: %s\t%s\t%s\nOSS:   %s\t%s\t%s ''' % (remark.encode('utf-8'),ucloud_private_ip.encode('utf-8'),ucloud_unicom_ip.encode('utf-8'),ucloud_telecom_ip.encode('utf-8'),oss_private_ip.encode('utf-8'),oss_unicom_ip.encode('utf-8'),oss_telecom_ip.encode('utf-8'))
				print error	
				print '======  index %s' % remark
				print '======  result %s' % res
				print '====== oss private ip *%s* ----  ucloud private ip *%s*' % (oss_private_ip,ucloud_private_ip)
				print '====== oss unicom ip *%s* ----  ucloud unicom ip *%s*' % (oss_unicom_ip,ucloud_unicom_ip)
				print '====== oss telecom ip *%s* ----  ucloud telecom ip *%s*' % (oss_telecom_ip,ucloud_telecom_ip)
			
				os.system('python /usr/local/zabbix/share/zabbix/alertscripts/sendrtx.py "%s" "%s"'% (recevier,error))
			break
		elif oss_host == len(func[0]):
			error =   'oss平台缺失 %s  主机信息!\nUcloud: %s\t%s\t%s\n' % (remark.encode('utf-8'),ucloud_private_ip.encode('utf-8'),ucloud_unicom_ip.encode('utf-8'),ucloud_telecom_ip.encode('utf-8'))
			os.system('python /usr/local/zabbix/share/zabbix/alertscripts/sendrtx.py "%s" "%s"'% (recevier,error))
		
	print '对比结束,无异常....' 
