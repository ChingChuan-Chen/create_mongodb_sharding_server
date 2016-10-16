# Install MongoDB Sharding Cluster
These scripts is modified from https://github.com/Azure/azure-quickstart-templates/tree/master/mongodb-sharding-centos

The setting for servers is 
```
replica set 1: 192.168.0.121 (primary), 192.168.0.122, 192.168.0.123
replica set 2: 192.168.0.124 (primary), 192.168.0.125, 192.168.0.126
config server: 192.168.0.127 (primary), 192.168.0.128, 192.168.0.129
router: 192.168.0.130, 192.168.0.131
```

You can use `replica_primary.sh` and `replica_secondary.sh` to create more replica sets.
And `router2.sh` for more router servers.

In your use, several things you must do:
1. To modify the IP addresses to the IPs of your config server in `config_primary.sh` at line 81,82.
1. To modify the IP addresses to the IPs of your config server in `router1.sh` at line 18,29,68.
1. To modify the IP addresses to the IPs of your primary sharding server in `router1.sh` at line 43,44.
   If you have more sharding servers, you can append the lines to line 43. `sh.addShard("replica_set_name/primary_sharding_IP:primary_sharding_IP")`
1. To modify the IP addresses to the IPs of your config server in `router2.sh` at line 15,26,50.

## install mongodb
``` bash
su
cd /home/tester/mongodb_config_scripts/
chmod +x *.sh
```
Implement `./install_mongodb.sh IP` in each computer.
ex: ./install_mongodb.sh 192.168.0.121

### replica set 1
for 192.168.0.121
``` bash
./replica_primary.sh rs1 192.168.0.121 drill drill
```
for 192.168.0.122,192.168.0.123
``` bash
./replica_secondary.sh rs1
```

### replica set 2
for 192.168.0.124
``` bash
./replica_primary.sh rs2 192.168.0.124 drill drill
```
for 192.168.0.125,192.168.0.126
``` bash
./replica_secondary.sh rs2
```

### config server
for 192.168.0.127
``` bash
./config_primary.sh drill drill
```
for 192.168.0.128,192.168.0.129
``` bash
./config_secondary.sh
```

### route1
for 192.168.0.130
``` bash
./router1.sh drill drill
```
for 192.168.0.131, ...
./router2.sh
```