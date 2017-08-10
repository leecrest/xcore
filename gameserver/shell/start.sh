# 获取当前用户名
USER_NAME=`echo "$USER"`

#获取脚本所在路径
IPATH=`pwd`
SHPATH=`echo ${0%/*}`
IDX=`echo $SHPATH|awk '{i=match($0,/\//);print i}'`
if [ $IDX = 1 ];then
    IPATH=$SHPATH
else
    IPATH=$IPATH/$SHPATH
fi
cd $IPATH
cd ..

NAME="xcore"


#查询pid
PID=`cat ./shell/xcore_pid0`
echo "关闭服务器："$PID
kill -9 $PID

#启动服务器
./xcore account/main.lua &
#将启动进程写入文件中
echo $! > ./shell/xcore_pid0
echo "进程启动成功"
