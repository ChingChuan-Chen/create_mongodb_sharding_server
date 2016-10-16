#!/bin/bash

replSetName=$1

firewall-cmd --zone=public --add-port=27017/tcp --permanent
firewall-cmd --reload

#set keyfile
echo "YZXhHsQMu7jBdygba8bPL14HIIuS7sF5QCSPGOnLeT+iez0eAGfV" > /etc/mongodb-keyfile
chown mongod:mongod /etc/mongodb-keyfile
chmod 600 /etc/mongodb-keyfile
sed -i 's/^#security/security/' /etc/mongod.conf
sed -i '/^security/akeyFile: /etc/mongodb-keyfile' /etc/mongod.conf
sed -i 's/^keyFile/  keyFile/' /etc/mongod.conf

#start replica set
mongod --dbpath /var/lib/mongo/ --config /etc/mongod.conf --replSet $replSetName --logpath /var/log/mongodb/mongod.log --fork

#check if mongod started or not
sleep 15
n=`ps -ef |grep "mongod --dbpath /var/lib/mongo/" |grep -v grep |wc -l`
if [[ $n -eq 1 ]];then
echo "replica set started successfully"
else
echo "replica set started failed!"
fi


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