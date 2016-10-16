#!/bin/bash

#set keyfile
echo "YZXhHsQMu7jBdygba8bPL14HIIuS7sF5QCSPGOnLeT+iez0eAGfV" > /etc/mongodb-keyfile
chown mongod:mongod /etc/mongodb-keyfile
chmod 600 /etc/mongodb-keyfile
sed -i 's/^#security/security/' /etc/mongod.conf
sed -i '/^security/akeyFile: /etc/mongodb-keyfile' /etc/mongod.conf
sed -i 's/^keyFile/  keyFile/' /etc/mongod.conf

firewall-cmd --zone=public --add-port=27017/tcp --permanent
firewall-cmd --reload

#start router server
mongos --configdb crepset/192.168.0.127:27019,192.168.0.128:27019,192.168.0.129:27019 --port 27017 --logpath /var/log/mongodb/mongos.log --fork --keyFile /etc/mongodb-keyfile

#check router server starts or not
for((i=1;i<=3;i++))
do
	sleep 30
	n=`ps -ef |grep "mongos --configdb" | grep -v grep |wc -l`
	if [[ $n -eq 1 ]];then
		echo "mongos started successfully"
		break
	else
		mongos --configdb crepset/192.168.0.127:27019,192.168.0.128:27019,192.168.0.129:27019 --port 27017 --logpath /var/log/mongodb/mongos.log --fork --keyFile /etc/mongodb-keyfile
		continue
	fi
done

n=`ps -ef |grep "mongos --configdb" | grep -v grep |wc -l`
if [[ $n -ne 1 ]];then
echo "mongos tried to start 3 times but failed!"
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
mongos --configdb crepset/192.168.0.127:27019,192.168.0.128:27019,192.168.0.129:27019--port 27017 --logpath /var/log/mongodb/mongos.log --fork --keyFile /etc/mongodb-keyfile
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
