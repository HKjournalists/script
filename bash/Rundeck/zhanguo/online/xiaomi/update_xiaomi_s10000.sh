 rsync -avz  /data/zhanguo_demo_gamecode/xiaomi/  --exclude "htdoc/resource"    /data/gamecode/xiaomi/backup/$(date +%Y-%m-%d-%H-%M)
 cd /data/gamecode/xiaomi/new/
 rsync     -aP   --exclude "config/app.conf.php*"  --exclude "htdoc/resource/*" --exclude ".svn/"  data xml   hot_version.txt    /data/zhanguo_demo_gamecode/xiaomi/
 hot_version_old=$(awk '/hot_version/{print $3}'  /data/zhanguo_demo_gamecode/xiaomi/config/app.conf.php|awk -F"," '{print $1}')
 hot_version_update=$(awk -F":" '{print $2}' hot_version.txt)
 sed  -i   -e "/hot_version/s/$hot_version_old/$hot_version_update/"  -e  "/hot_update_url/s/1.6.0.$hot_version_old/1.6.0.$hot_version_update/"   /data/zhanguo_demo_gamecode/xiaomi/config/app.conf.php
 sudo service php-fpm reload 
