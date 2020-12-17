#! /bin/bash

#Adding hostnames of the containers to VM /etc/hosts :
export web1_host_ip="1 i\172.17.0.2 web1";
export web2_host_ip="1 i\172.17.0.3 web2";
export web3_host_ip="1 i\172.17.0.4 web3";
export haproxy_host_ip="1 i\172.17.0.5 haproxy";
export dbgc1_host_ip="1 i\172.17.0.6 dbgc1";
export dbgc2_host_ip="1 i\172.17.0.7 dbgc2";
export dbgc3_host_ip="1 i\172.17.0.8 dbgc3";
export maxscale_host_ip="1 i\172.17.0.9 maxscale";

# images
export php_image= richarvey/nginx-php-fpm;
export haproxy_image=haproxy:latest;
export maria_image=mariadb:10.4;
export maria_max_image=mariadb/maxscale:latest;
#webserver
export web1_name=web1;
export web2_name=web2;
export web3_name=web3; 
export web1_host=web1;
export web2_host=web2;
export web3_host=web3;

#host
export web1_hosts=web1:172.17.0.2;
export web2_hosts=web2:172.17.0.3;
export web3_hosts=web3:172.17.0.4;
export haproxy_hosts=haproxy:172.17.0.5;
export dbgc1_hosts=dbgc1:172.17.0.6;
export dbgc2_hosts=dbgc2:172.17.0.7;
export dbgc3_hosts=dbgc3:172.17.0.8;
export maxscale_hosts=maxscale:172.17.0.9;

#volumes
export web1_volume=/home/ubuntu/volumes/web1/web/html:/var/www/html/:ro;
export web2_volume=/home/ubuntu/volumes/web2/web/html:/var/www/html/:ro;
export web3_volume=/home/ubuntu/volumes/web3/web/html:/var/www/html/:ro;
export lb_volume=/home/ubuntu/volumes/lb/:/usr/local/etc/haproxy/;

export db1_volume_datadir=/home/ubuntu/volumes/db1/datadir:/var/lib/mysql ;
export db1_volume_conf=/home/ubuntu/volumes/db1/conf.d:/etc/mysql/mariadb.conf.d;

export db2_volume_datadir=/home/ubuntu/volumes/db2/datadir:/var/lib/mysql;
export db2_volume_conf=/home/ubuntu/volumes/db2/conf.d:/etc/mysql/mariadb.conf.d;

export db3_volume_datadir=/home/ubuntu/volumes/db3/datadir:/var/lib/mysql;
export db3_volume_conf=/home/ubuntu/volumes/db3/conf.d:/etc/mysql/mariadb.conf.d;

export maxscale_volume=/home/ubuntu/volumes/dbproxy/:/etc/maxscale.cnf.d/;
#create lb
export lb_name=lb;
export lb_host=haproxy;

#run db1:
export db1_name=db1;
export db1_host=dbgc1;

#run db2:
export db2_name=db2;
export db2_host=dbgc2;

#run db3:
export db3_name=db3;
export db3_host=dbgc3;
# run dbproxy
export dbproxy_name=dbproxy;
export dbproxy_host=maxscale;

#add host
export db1_ip=dbgc1:172.17.0.6;
export db2_ip=dbgc2:172.17.0.7;
export db13_ip=dbgc3:172.17.0.8;
# password and user
export mysql_root_pass="rootpass";
export mysql_root="root";
export maxscale_user="maxscaleuser";
export maxscale_pass="maxscalepass";
export dats25_pass="express much room";
export dats25_name="dats25";
#mysql;
export port_publish_1="3306";
export port_publish_2="4444";
export port_publish_3="4567";
export port_publish_4="4568";

#run maxscale
export maxscale_name=dbproxy;
export max_host=maxscale;

#sudo docker exec -i db1 mysql -uroot -prootpass <<< "GRANT SHOW DATABASE ON *.* TO 'maxscaleuser'@'172.17.0.%';"
#sleep 10
#sudo docker exec -i db1 mysql -uroot -prootpass <<< "GRANT SELECT ON `mysql`.* TO 'maxscaleuser'@'172.17.0.%';"
#sleep 10 