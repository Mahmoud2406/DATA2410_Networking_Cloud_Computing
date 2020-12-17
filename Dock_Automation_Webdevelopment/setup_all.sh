#! /bin/bash

mkdir -p  ~/volumes/web1/web/html \
volumes/web1/web/html \
volumes/web2/web/html \
volumes/web3/web/html \
volumes/lb/haproxy \
volumes/db1/conf.d \
volumes/db1/datadir \
volumes/db2/conf.d  \
volumes/db2/datadir \
volumes/db3/conf.d  \
volumes/db3/datadir \
volumes/dbproxy


sudo sed -i "1 i\172.17.0.2 web1" /etc/hosts
sudo sed -i "1 i\172.17.0.3 web2" /etc/hosts
sudo sed -i "1 i\172.17.0.4 web3" /etc/hosts
sudo sed -i "1 i\172.17.0.5 haproxy" /etc/hosts
sudo sed -i "1 i\172.17.0.6 dbgc1" /etc/hosts
sudo sed -i "1 i\172.17.0.7 dbgc2" /etc/hosts
sudo sed -i "1 i\172.17.0.8 dbgc3" /etc/hosts
sudo sed -i "1 i\172.17.0.9 maxscale" /etc/hosts



sudo docker create --name web1 \
--hostname=web1 \
-p 81:80 \
--add-host=web2:172.17.0.3 \
--add-host=web3:172.17.0.4 \
--add-host=haproxy:172.17.0.5 \
--add-host=dbgc1:172.17.0.6 \
--add-host=dbgc2:172.17.0.7 \
--add-host=dbgc3:172.17.0.8 \
--add-host=maxscale:172.17.0.9 \
-v /home/ubuntu/volumes/web1/web/html:/var/www/html/:ro \
richarvey/nginx-php-fpm


sudo docker create --name web2 \
--hostname=web2 \
-p 82:80 \
--add-host=web1:172.17.0.2 \
--add-host=web3:172.17.0.4 \
--add-host=haproxy:172.17.0.5 \
--add-host=dbgc1:172.17.0.6 \
--add-host=dbgc2:172.17.0.7 \
--add-host=dbgc3:172.17.0.8 \
--add-host=maxscale:172.17.0.9 \
-v /home/ubuntu/volumes/web2/web/html:/var/www/html/:ro \
richarvey/nginx-php-fpm


sudo docker create --name web3 \
--hostname=web3 \
-p 83:80 \
--add-host=web1:172.17.0.2 \
--add-host=web2:172.17.0.3 \
--add-host=haproxy:172.17.0.5 \
--add-host=dbgc1:172.17.0.6 \
--add-host=dbgc2:172.17.0.7 \
--add-host=dbgc3:172.17.0.8 \
--add-host=maxscale:172.17.0.9 \
-v /home/ubuntu/volumes/web3/web/html:/var/www/html/:ro \
richarvey/nginx-php-fpm

sudo docker start web1 web2 web3


echo -e '

 # Simple configuration for an HTTP proxy listening on port 80 on all
 # interfaces and forwarding requests to a single backend "servers" with a
 # single server "server1" listening on 127.0.0.1:8000
    global
        daemon
        maxconn 256

    defaults
        mode http
        timeout connect 5000ms
        timeout client 50000ms
        timeout server 50000ms


frontend myfrontend
bind *:80
mode http
default_backend mybackend


backend mybackend
mode http
balance roundrobin
option httpchk HEAD / # checks against the index page

server web1 172.17.0.2:80 check
server web2 172.17.0.3:80 check
server web3 172.17.0.4:80 check

'  >>  ~/volumes/lb/haproxy.cfg

sudo docker run  --name=lb --hostname=haproxy -d -p 80:80  -v /home/ubuntu/volumes/lb:/usr/local/etc/haproxy/ haproxy:latest


#config til db

echo -e '
[galera]
binlog_format=ROW
default-storage-engine=innodb
innodb_autoinc_lock_mode=2
bind-address=0.0.0.0
# Galera Provider Configuration
wsrep_on=ON
wsrep_provider=/usr/lib/galera/libgalera_smm.so
# Galera Cluster Configuration
wsrep_cluster_address=gcomm://
# Galera Synchronization Configuration
wsrep_sst_method=rsync


[mysqld]

innodb_flush_log_at_trx_commit= 0
innodb_flush_method = O_DIRECT
#innodb_file_per_table= 1
innodb_autoinc_lock_mode= 2
#innodb_lock_schedule_algorithm FCFS # MariaDB >10.1.19 and >10.2.3 only

' >> ~/volumes/db1/conf.d/my.cnf



sudo docker run -d --name db1 --hostname dbgc1 --publish "3306" --publish "4444" --publish "4567" --publish "4568" --env MYSQL_ROOT_PASSWORD="rootpass" --env MYSQL_USER=dats25 --env MYSQL_PASSWORD="express much room" --volume /home/ubuntu/volumes/db1/datadir:/var/lib/mysql --volume /home/ubuntu/volumes/db1/conf.d:/etc/mysql/mariadb.conf.d mariadb:10.4


sleep 10

sudo grep -q safe_to_bootstrap: ~/volumes/db1/datadir/grastate.dat && sudo sed -i '/safe_to_bootstrap:/c\safe_to_bootstrap: 1' ~/volumes/db1/datadir/grastate.dat

sleep 10

echo -e '
[galera]
binlog_format=ROW
default-storage-engine=innodb
innodb_autoinc_lock_mode=2
bind-address=0.0.0.0
# Galera Provider Configuration
wsrep_on=ON
wsrep_provider=/usr/lib/galera/libgalera_smm.so
# Galera Cluster Configuration
wsrep_cluster_address="gcomm://172.17.0.6,172.17.0.7,172.17.0.8"
# Galera Synchronization Configuration
wsrep_sst_method=rsync


[mysqld]

innodb_flush_log_at_trx_commit= 0
innodb_flush_method = O_DIRECT
#innodb_file_per_table= 1
innodb_autoinc_lock_mode= 2
#innodb_lock_schedule_algorithm FCFS # MariaDB >10.1.19 and >10.2.3 only
' >> ~/volumes/db2/conf.d/my.cnf


sudo docker run -d --name db2 --hostname dbgc2 -p 3306 -p 4444 -p 4567 -p 4568 -e MYSQL_ROOT_PASSWORD="rootpass" -e MYSQL_USER="maxscaleuser" -e MYSQL_PASSWORD="maxscalepass" -v /home/ubuntu/volumes/db2/datadir:/var/lib/mysql -v /home/ubuntu/volumes/db2/conf.d:/etc/mysql/mariadb.conf.d --add-host dbgc1:172.17.0.6 --add-host dbgc3:172.17.0.8 mariadb:10.4

wait 10
 sudo docker restart db2

echo -e '
[galera]
binlog_format=ROW
default-storage-engine=innodb
innodb_autoinc_lock_mode=2
bind-address=0.0.0.0
# Galera Provider Configuration
wsrep_on=ON
wsrep_provider=/usr/lib/galera/libgalera_smm.so
# Galera Cluster Configuration
wsrep_cluster_address="gcomm://172.17.0.6,172.17.0.7,172.17.0.8"
# Galera Synchronization Configuration
wsrep_sst_method=rsync


[mysqld]

innodb_flush_log_at_trx_commit= 0
innodb_flush_method = O_DIRECT
#innodb_file_per_table= 1
innodb_autoinc_lock_mode= 2
#innodb_lock_schedule_algorithm FCFS # MariaDB >10.1.19 and >10.2.3 only
' >> ~/volumes/db3/conf.d/my.cnf


sudo docker run -d --name db3 --hostname dbgc3 -p 3306 -p 4444 -p 4567 -p 4568 -e MYSQL_ROOT_PASSWORD="rootpass" -e MYSQL_USER="maxscaleuser" -e MYSQL_PASSWORD="maxscalepass" -v /home/ubuntu/volumes/db3/datadir:/var/lib/mysql -v /home/ubuntu/volumes/db3/conf.d:/etc/mysql/mariadb.conf.d --add-host dbgc1:172.17.0.6 --add-host dbgc3:172.17.0.8 mariadb:10.4

wait 10
 sudo docker restart db3

echo -e '
########################
## Server list
########################

[db1]
type            = server
address         = 172.17.0.6
port            = 3306
protocol        = MariaDBBackend
serv_weight     = 1

[db2]
type            = server
address         = 172.17.0.7
port            = 3306
protocol        = MariaDBBackend
serv_weight     = 1

[db3]
type            = server
address         = 172.17.0.8
port            = 3306
protocol        = MariaDBBackend
serv_weight     = 1

#########################
## MaxScale configuration
#########################

#[maxscale]
#threads                 = auto
#log_augmentation        = 1
#ms_timestamp            = 1
#syslog                  = 1

#########################
# Monitor for the servers
#########################

#[monitor]
#type                    = monitor
#module                  = mariadbmon
#servers                 = db1,db2,db3
#user                    = maxscale
#password                = maxscalepass
#auto_failover           = true
#auto_rejoin             = true
#enforce_read_only_slaves = 1


[MariaDB-Monitor]
type=monitor
module = galeramon
servers = db1,db2,db3
user =maxscaleuser
password = maxscalepass
monitor_interval = 2000
disable_master_failback =1

[Read-Write-Listener]
type = listener
service = Read-Write-Service
protocol = MariaDBClient
port = 3306
address = 0.0.0.0

[Read-Write-Service]
type = service
router = readwritesplit
servers =db1,db2,db3
user = maxscaleuser
password = maxscalepass
slave_selection_criteria = LEAST_GLOBAL_CONNECTIONS
master_failure_mode = error_on_write
max_slave_connections = 1
weightby = serv_weight
enable_root_user = true
' >> ~/volumes/dbproxy/maxscale.cnf


sudo docker run -d --name dbproxy --hostname maxscale \
-e MYSQL_USER="maxscaleuser" \
-e MYSQL_PASSWORD="maxscalepass" \
 -v /home/ubuntu/volumes/dbproxy/:/etc/maxscale.cnf.d/ mariadb/maxscale:latest

# appication
git clone  https://github.com/AdAli92/database.git
sleep 10
cp ~/database/studentinfo-db.sql ~/volumes/db1/datadir/

git clone https://github.com/AdAli92/phpcode.git
sleep 10
cd  phpcode
cp  index.php delete.php create.php update.php stylesheet.css ~/volumes/web1/web/html/
cp -arv include ~/volumes/web1/web/html/
cp  index.php delete.php create.php update.php stylesheet.css ~/volumes/web2/web/html/
cp -arv include ~/volumes/web2/web/html/
cp  index.php delete.php create.php update.php stylesheet.css ~/volumes/web3/web/html/
cp -arv include ~/volumes/web3/web/html/

cd ..
sudo rm -r phpcode
sudo rm -r database


# Grant
sudo docker exec -i db1 mysql -uroot -prootpass <<< "source /var/lib/mysql/studentinfo-db.sql;"
sleep 10
sudo docker exec -i db1 mysql -uroot -prootpass <<< "CREATE USER 'maxscaleuser'@'172.17.0.%' IDENTIFIED BY 'maxscalepass';"
sleep 10
sudo docker exec -i db1 mysql -uroot -prootpass <<< "GRANT ALL PRIVILEGES ON *.* TO 'maxscaleuser'@'172.17.0.%';"
sleep 10
sudo docker exec -i db1 mysql -uroot -prootpass <<< "GRANT SHOW DATABASE ON *.* TO 'maxscaleuser'@'172.17.0.%';"
#sleep 10
sudo docker exec -i db1 mysql -uroot -prootpass <<< "GRANT SELECT ON `mysql`.* TO 'maxscaleuser'@'172.17.0.%';"
#sleep 10 
sudo docker exec -i db1 mysql -uroot -prootpass <<< "CREATE USER 'dats25'@'172.17.0.%' IDENTIFIED BY 'express much room';"
sleep 10
sudo docker exec -i db1 mysql -uroot -prootpass <<< "GRANT ALL PRIVILEGES ON *.* TO 'dats25'@'172.17.0.%';"
sleep 10