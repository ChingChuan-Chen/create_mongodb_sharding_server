#!/bin/bash

cat > /etc/yum.repos.d/mongodb-org-3.2.repo <<EOF
[mongodb-org-3.2]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/3.2/x86_64/
gpgcheck=0
enabled=1
EOF

#install
yum install -y mongodb-org

#ignore update
sed -i '$a exclude=mongodb-org,mongodb-org-server,mongodb-org-shell,mongodb-org-mongos,mongodb-org-tools' /etc/yum.conf

#disable selinux
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/sysconfig/selinux
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
setenforce 0

#kernel settings
if [[ -f /sys/kernel/mm/transparent_hugepage/enabled ]];then
  echo never > /sys/kernel/mm/transparent_hugepage/enabled
fi
if [[ -f /sys/kernel/mm/transparent_hugepage/defrag ]];then
  echo never > /sys/kernel/mm/transparent_hugepage/defrag
fi

cat /etc/init.d/transparent_hugepage <<EOF
if [[ -f /sys/kernel/mm/transparent_hugepage/enabled ]];then
  echo never > /sys/kernel/mm/transparent_hugepage/enabled
fi
if [[ -f /sys/kernel/mm/transparent_hugepage/defrag ]];then
  echo never > /sys/kernel/mm/transparent_hugepage/defrag
fi
EOF
chkconfig transparent_hugepage on

#configure
sed -i 's/\(bindIp\)/#\1/' /etc/mongod.conf

