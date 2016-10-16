#!/bin/bash

replSetName=$1
staticIP=$2
mongoAdminUser=$3
mongoAdminPasswd=$4

firewall-cmd --zone=public --add-port=27017/tcp --permanent
firewall-cmd --reload

#start mongod
mongod --dbpath /var/lib/mongo/ --logpath /var/log/mongodb/mongod.log --fork

sleep 30
n=`ps -ef |grep "mongod --dbpath /var/lib/mongo/" |grep -v grep |wc -l`
if [[ $n -eq 1 ]];then
	echo "mongod started successfully"
else
	echo "mongod started failed!"
fi

#create users
mongo <<EOF
use admin
db.createUser({user:"$mongoAdminUser",pwd:"$mongoAdminPasswd",roles:[{role: "userAdminAnyDatabase", db: "admin" },{role: "readWriteAnyDatabase", db: "admin" },{role: "root", db: "admin" }]})
exit
EOF
if [[ $? -eq 0 ]];then
	echo "mongo user added succeefully."
else
	echo "mongo user added failed!"
fi

#stop mongod
sleep 15
MongoPid=`ps -ef |grep "mongod --dbpath /var/lib/mongo/" |grep -v grep |awk '{print $2}'`
kill -2 $MongoPid

#set keyfile
echo "YZXhHsQMu7jBdygba8bPL14HIIuS7sF5QCSPGOnLeT+iez0eAGfV" > /etc/mongodb-keyfile
chown mongod:mongod /etc/mongodb-keyfile
chmod 600 /etc/mongodb-keyfile
sed -i 's/^#security/security/' /etc/mongod.conf
sed -i '/^security/akeyFile: /etc/mongodb-keyfile' /etc/mongod.conf
sed -i 's/^keyFile/  keyFile/' /etc/mongod.conf

# sed -i 's/keyFile: \/etc\/mongodb-keyfile//' /etc/mongod.conf
# sed -i 's/^security/#security/' /etc/mongod.conf

sleep 15
MongoPid1=`ps -ef |grep "mongod --dbpath /var/lib/mongo/" |grep -v grep |awk '{print $2}'`
if [[ -z $MongoPid1 ]];then
	echo "shutdown mongod successfully"
else
	echo "shutdown mongod failed!"
	kill $MongoPid1
	sleep 15
fi

#restart mongod with auth and replica set
mongod --dbpath /var/lib/mongo/ --replSet $replSetName --logpath /var/log/mongodb/mongod.log --fork --config /etc/mongod.conf

#initiate replica set
for((i=1;i<=3;i++))
do
	sleep 15
	n=`ps -ef |grep "mongod --dbpath /var/lib/mongo/" |grep -v grep |wc -l`
	if [[ $n -eq 1 ]];then
		echo "mongo replica set started successfully"
		break
	else
		mongod --dbpath /var/lib/mongo/ --replSet $replSetName --logpath /var/log/mongodb/mongod.log --fork --config /etc/mongod.conf
		continue
	fi
done

n=`ps -ef |grep "mongod --dbpath /var/lib/mongo/" |grep -v grep |wc -l`
if [[ $n -ne 1 ]];then
	echo "mongo replica set tried to start 3 times but failed!"
fi

mongo<<EOF
use admin
db.auth("$mongoAdminUser", "$mongoAdminPasswd")
config ={_id:"$replSetName",members:[{_id:0,host:"$staticIP:27017"}]}
rs.initiate(config)
exit
EOF
if [[ $? -eq 0 ]];then
	echo "replica set initiation succeeded."
else
	echo "replica set initiation failed!"
fi

#get replica secondary nodes ips
num=`echo $staticIP |awk -F"." '{print $NF}'`
if [[ $num -eq 121 ]];then
	let g=121
elif [[ $num -eq 124 ]];then
	let g=124
fi

#add secondary nodes
for((i=1;i<=2;i++))
do
	let a=$i+$g
	mongo -u "$mongoAdminUser" -p "$mongoAdminPasswd" "admin" --eval "printjson(rs.add('192.168.0.${a}:27017'))"
	if [[ $? -eq 0 ]];then
		echo "adding server 192.168.0.${a} successfully"
	else
		echo "adding server 192.168.0.${a} failed!"
	fi
done

#set mongod auto start
cat > /etc/init.d/mongod1 <<EOF
#!/bin/bash
#chkconfig: 35 84 15
#description: mongod auto start
. /etc/init.d/functions

if [[ -f /sys/kernel/mm/transparent_hugepage/enabled ]];then
  echo never > /sys/kernel/mm/transparent_hugepage/enabled
fi
if [[ -f /sys/kernel/mm/transparent_hugepage/defrag ]];then
  echo never > /sys/kernel/mm/transparent_hugepage/defrag
fi

Name=mongod1
start() {
if [[ ! -d /var/run/mongodb ]];then
mkdir /var/run/mongodb
chown -R mongod:mongod /var/run/mongodb
fi
mongod --dbpath /var/lib/mongo/ --replSet $replSetName --logpath /var/log/mongodb/mongod.log --fork --config /etc/mongod.conf
}
stop() {
pkill mongod
}
restart() {
stop
sleep 15
start
}

case "\$1" in 
    start)
	start;;
	stop)
	stop;;
	restart)
	restart;;
	status)
	status \$Name;;
	*)
	echo "Usage: service mongod1 start|stop|restart|status"
esac
EOF
chmod +x /etc/init.d/mongod1
chkconfig mongod1 on

