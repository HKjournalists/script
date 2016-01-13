#!/bin/bash
##备份远程数据库数据到本地
#--------- backup argument ------------
CURRENT_DATE=$(date  +%Y%m%d)
#CURRENT_DATE=$(date  +%Y%m%d -d "1 days ago")
PLAT_DATA=/data/tools/platform.txt
PLATFORM="taiwan disney jidong dawushi viet  apple xinchang japan"
INCLUDE="login game mongodb redis mysql"

#----------- mysql argument ------------
HOST=127.0.0.1
USER=xxx
PASSWORD=xxxx
DATABASE=jd_oss
TABLE=dbbackup
MYSQL_CONN="mysql -h$HOST -u$USER -p$PASSWORD  $DATABASE -e"
#速率限制
LIMIT=1500
dbbackup_time="$(date +"%F %R:%S")"

function insert_mysql(){
        #----------- mysql keys --------------
        dbbackup_id=$(expr `$MYSQL_CONN  "set names utf8;select max(dbbackup_id) from dbbackup" | sed -n '1d;p'` + 1)
        dbbackup_name="system backup"
        dbbackup_dbname="${platform}_${include}"
        dbbackup_size=$(expr $(du -s ${BACKUP_DIR}/${PROJECT}/${platform} | cut -f1) / 1024)
        dbbackup_type="自动"
        dbbackup_status=$dbbackup_status
        dbbackup_project=$(grep "${platform}" ${PLAT_DATA}|awk 'END{print $2}')
        dbbackup_dbtype="$include"
        $MYSQL_CONN "set names utf8;insert into dbbackup (dbbackup_id,dbbackup_name,dbbackup_dbname,dbbackup_size,dbbackup_type,dbbackup_status,dbbackup_project,dbbackup_dbtype,dbbackup_time) values($dbbackup_id,'$dbbackup_name','$dbbackup_dbname','$dbbackup_size','$dbbackup_type','$dbbackup_status','$dbbackup_project','$dbbackup_dbtype','$dbbackup_time');"
}

function checksum(){
                [ -d ${BACKUP_DIR}/${PROJECT}/${platform} ] || mkdir -p ${BACKUP_DIR}/${PROJECT}/${platform}
                cd ${BACKUP_DIR}/${PROJECT}/${platform}
                #--- 获取 远程的md5文件 ------
                rsync -avz $IP::backup/${include}/checksum${CURRENT_DATE}.txt ${BACKUP_DIR}/${PROJECT}/${platform}/checksum${CURRENT_DATE}.txt 
                #--- 每3个为组进行读取内容 并拉回本地 -----
		{
                awk '{if(NR%3==1)print $2}' checksum${CURRENT_DATE}.txt | xargs -n1 -i rsync -avz --progress --bwlimit=${LIMIT}  $IP::backup/${include}/{}  ${BACKUP_DIR}/${PROJECT}/${platform} 
                awk '{if(NR%3==2)print $2}' checksum${CURRENT_DATE}.txt | xargs -n1 -i rsync -avz --progress --bwlimit=${LIMIT}  $IP::backup/${include}/{}  ${BACKUP_DIR}/${PROJECT}/${platform} 
                awk '{if(NR%3==0)print $2}' checksum${CURRENT_DATE}.txt | xargs -n1 -i rsync -avz  --progress --bwlimit=${LIMIT}  $IP::backup/${include}/{}  ${BACKUP_DIR}/${PROJECT}/${platform} 
		}&
		wait
		cd ${BACKUP_DIR}/${PROJECT}/${platform}	
		sed -i '/checksum/d' ${BACKUP_DIR}/${PROJECT}/${platform}/checksum${CURRENT_DATE}.txt
                ls *${CURRENT_DATE}*|grep -v check | xargs -n1 -i md5sum {} >> ${BACKUP_DIR}/${PROJECT}/${platform}/checksum${CURRENT_DATE}.txt
                #----- 校验 -----
                md5sum -c ${BACKUP_DIR}/${PROJECT}/${platform}/checksum${CURRENT_DATE}.txt && dbbackup_status="备份成功"
		include=$include_tmp 
                insert_mysql
}

for platform  in ${PLATFORM}
do
	PROJECT=$(grep "${platform}" ${PLAT_DATA}|awk 'END{print $4}')
	for include in $INCLUDE
	do
		include_tmp=$include
		dbbackup_status="备份失败"
		BACKUP_DIR="/data/backup/all_database/${include}"

	case $include in 
		"game_code")
	        	LOGIN=$(grep "${platform}_login" ${PLAT_DATA}|awk '{print $3}') && IP=$LOGIN
	        	GAME=$(grep "${platform}_game" ${PLAT_DATA}|awk '{print $3}') && IP=$GAME
			[ -z $LOGIN -o -z $GAME ] && continue
			BACKUP_DIR="/data/backup/${include}"		

			 #------  disney code ------
			if [ $PROJECT = "jialebi" ];then 
			rsync -vzrtopg --bwlimit=1000 $IP::backup/game_{center,server}/${CURRENT_DATE}* ${BACKUP_DIR}/${PROJECT}/${platform}  & 
			else
			rsync -vzrtopg --bwlimit=1000 $IP::game_code  ${BACKUP_DIR}/${PROJECT}/${platform} &
			fi
		;;
		"redis")
	        	REDIS=$(grep "${platform}_redis" ${PLAT_DATA}|awk '{print $3}') && IP=$REDIS
			[ -z $REDIS ] && continue 
			#------如果为jialebi 使用带日期目录格式
			[ $PROJECT = "jialebi" ] && include="$include/${CURRENT_DATE}22"
			checksum
		;;
		"mysql")
	        	MYSQL=$(grep "${platform}_mysql" ${PLAT_DATA}|awk '{print $3}') && IP=$MYSQL			
			[ -z $MYSQL ] && continue 
			checksum	
		;;
		"mongodb")
	        	MONGO=$(grep "${platform}_mongodb" ${PLAT_DATA}|awk '{print $3}') && IP=$MONGO
	                [ -z $MONGO ] && continue
			[ $PROJECT = "jialebi" ] && continue
			checksum
		;;
		*)
		esac		
	#删除15天前数据
	find ${BACKUP_DIR}/${PROJECT}/${platform}  -ctime +15 -exec rm -rf {} \;
       done
done
