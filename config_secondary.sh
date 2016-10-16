#!/bin/bash

firewall-cmd --zone=public --add-port=27019/tcp --permanent
firewall-cmd --reload

#set keyfile
echo "YZXhHsQMu7jBdygba8bPL14HIIuS7sF5QCSPGOnLeT+iez0eAGfV" > /etc/mongodb-keyfile
chown mongod:mongod /etc/mongodb-keyfile
chmod 600 /etc/mongodb-keyfile
sed -i 's/^#security/security/' /etc/mongod.conf
sed -i '/^security/akeyFile: /etc/mongodb-keyfile' /etc/mongod.conf
sed -i 's/^keyFile/  keyFile/' /etc/mongod.conf

#start config replica set
mongod --configsvr --replSet crepset --port 27019 --dbpath /var/lib/mongo/ --logpath /var/log/mongodb/config.log --fork --config /etc/mongod.conf

#check if mongod started or not
sleep 15
n=`ps -ef |grep "mongod --configsvr" |grep -v grep |wc -l`
if [[ $n -eq 1 ]];then
    echo "mongod config replica set started successfully"
else
    echo "mongod config replica set started failed!"
fi


#set mongod auto start
cat > /etc/init.d/mongod1 <<EOF
#!/bin/bash
#chkconfig: 35 84 15
#description: mongod auto start
. /etc/init.d/functions

Name=mongod1
start() {
if [[ ! -d /var/run/mongodb ]];then
mkdir /var/run/mongodb
chown -R mongod:mongod /var/run/mongodb
fi
mongod --configsvr --replSet crepset --port 27019 --dbpath /var/lib/mongo/ --logpath /var/log/mongodb/config.log --fork --config /etc/mongod.conf
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