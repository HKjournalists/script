#platform=jidong
#version=1.0.0
#cat /data/gintama_app/jidong_new/game_code/config/jidong/version.ini 
#base_version = 1
#hot_version  = 1

platform=$1
version=$2
YIWAN="gintama-baidu-demo"

function update_code () {
    prod_svn_dir=/data/svn/prod/$platform/$version/
    cdn_dir=/data/cdn_data/resource/$platform/$version/
    qa_gamecode_dir=/data/gintama_app/${platform}_new/game_code/
    hot_version=$(grep hot_version $qa_gamecode_dir/config/bdyy/version_old.ini|awk '{print $3}'|uniq)
    svn up $prod_svn_dir
    sudo rsync -avz    --exclude "config/" --exclude ".svn"  $prod_svn_dir/game_code    $YIWAN::${platform}_songshen
    sudo rsync -avz    $qa_gamecode_dir/config/bdyy/version_old.ini    $qa_gamecode_dir/config/bdyy/rand_name.php     $qa_gamecode_dir/config/bdyy/sensitive_words.php       $YIWAN::${platform}_songshen/game_code/config/bdyy/

    sudo rsync -avz    --exclude ".svn" $cdn_dir/$hot_version $YIWAN::${platform}_songshen_cdn/$version
    sudo rsync -avz    --exclude ".svn" /data/cdn_data/resource/$platform/sound/ $YIWAN::${platform}_songshen_cdn/sound/

                        }

if [ "$platform" != "" -a "$version" != "" ];then
   update_code
else
   echo -e "\e[105mPlatform name and version should be given\e[0m"
   echo -e "\e[105mUsage: $0 jidong 1.0.0\e[0m"
fi
