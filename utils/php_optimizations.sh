#!/bin/bash
#
# Autor: broobe. web + mobile development - https://broobe.com
# Version: 2.9
################################################################################
#
# Calculating pm.max_children
# An example: if our cloud server has 4 GB RAM and a MariaDB database service is running as well that consumes at least 1 GB our best aim is to get 4 - 1 - 0,5 (marge) GB = 2,5 GB RAM or 2560 Mb.
# pm.max_children brings us to 2560 Mb / 60 Mb = 42 max_children
# We have made the following changes in our www.conf file in the php-fpm pool:
# pm.max_children = 40
# pm.start_servers = 15
# pm.min_spare_servers = 15
# pm.max_spare_servers = 25
# pm.max_requests = 500
# Restart the php-fpm service and see if the server behaves in a correct manner and allocates memory as configured.
#
################################################################################

# TODO: antes que nada deberiamos checkear donde está la config de php
# TODO: checkear si existe más de una versión de php instalada
# TODO: en caso de que exista más de una versión, preguntar cual vamos a optimizar

PHP_V="7.2"  # TODO: Ubuntu 18.04 LTS Default pero habria que checkear cual está instalado
RAM_BUFFER="512"

# Getting server info
CPUS=$(grep -c "processor" /proc/cpuinfo)
RAM=$(grep MemTotal /proc/meminfo | awk '{print $2}' | xargs -I {} echo "scale=0; {}/1024^2" | bc)

# Calculating avg ram used by this process
PHP_AVG_RAM=$(ps --no-headers -o "rss,cmd" -C php-fpm${PHP_V} | awk '{ sum+=$1 } END { printf ("%d%s\n", sum/NR/1024,"Mb") }')
MYSQL_AVG_RAM=$(ps --no-headers -o "rss,cmd" -C mysqld | awk '{ sum+=$1 } END { printf ("%d%s\n", sum/NR/1024,"Mb") }')

# php.ini broobe standard configuration
#echo " > Moving php configuration file ..." >>$LOG
#cat confs/php.ini > /etc/php/${PHP_V}/fpm/php.ini

# fpm broobe standard configuration
#echo " > Moving fpm configuration file ..." >>$LOG
#cat confs/php/${SERVER_MODEL}/www.conf > /etc/php/${PHP_V}/fpm/pool.d/www.conf

# pm.max_children = (RAM*1024 - (MYSQL_AVG_RAM - RAM_BUFFER)) / PHP_AVG_RAM
# pm.start_servers = pm.max_children / 4
# pm.min_spare_servers = pm.start_servers
# pm.max_spare_servers = pm.start_servers * 2
# pm.max_requests = 500
#
# PROBAR ESTO
#
#s/^\(pm.max_children = \).*/\15/               # va a escribir: pm.max_children = 5
#s/^\(pm.start_servers = \).*/\11/
#s/^\(pm.min_spare_servers = \).*/\11/
#s/^\(pm.max_spare_servers = \).*/\13/
#s/^\(pm.max_requests = \).*/\12000/
#
# O ESTO
#
#s/^[#;]*\(pm.max_children = \).*/\15/g