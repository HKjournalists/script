version=1.7.0
svndir=/svn/channels/$version/game_server/
svn up $svndir
sudo rsync  -aP  --exclude ".svn/"  --exclude "config"  $svndir   101.66.253.186::360songshen
