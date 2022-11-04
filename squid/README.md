

# Шаг 1. Создадим минимальную конфигурацию для нашего прокси сервера: squid.conf
```
http_port 3128

acl localnet src 10.0.0.0/8     # RFC1918 possible internal network
acl localnet src 172.16.0.0/12  # RFC1918 possible internal network
acl localnet src 192.168.0.0/16 # RFC1918 possible internal network
acl localnet src fc00::/7       # RFC 4193 local private network range
acl localnet src fe80::/10      # RFC 4291 link-local (directly plugged) machines

acl SSL_ports port 443

acl Safe_ports port 80          # http
acl Safe_ports port 21          # ftp
acl Safe_ports port 443         # https
acl Safe_ports port 70          # gopher
acl Safe_ports port 210         # wais
acl Safe_ports port 280         # http-mgmt
acl Safe_ports port 488         # gss-http
acl Safe_ports port 591         # filemaker
acl Safe_ports port 777         # multiling http
acl Safe_ports port 1025-65535  # unregistered ports

acl CONNECT method CONNECT

http_access deny !Safe_ports
http_access deny CONNECT !SSL_ports
http_access allow localhost manager
http_access deny manager

#
# INSERT YOUR OWN RULE(S) HERE TO ALLOW ACCESS FROM YOUR CLIENTS
#

http_access allow localnet
http_access allow localhost
http_access deny all

coredump_dir /var/spool/squid

refresh_pattern ^ftp:           1440    20%     10080
refresh_pattern ^gopher:        1440    0%      1440
refresh_pattern -i (/cgi-bin/|\?) 0     0%      0
refresh_pattern .               0       20%     4320
```
# Подготовим директории
```
mkdir -p /srv/docker/squid/cache
mkdir -p /var/log/squid
```

# Создадим Docker-compose файл.

```
version: '3'

services:
  squid:
	image: ubuntu/squid:5.2-22.04_beta
    ports:
	 - '3128:3128'
	volumes:
	 - ./squid.conf:/etc/squid/squid.conf:ro
     - /var/log/squid:/var/log/squid
	 - /srv/docker/squid/cache:/var/spool/squid
    restart: always
```
# Проверка squid
```
curl -x http://0.0.0.0:3128 -L https://ya.ru
```

# Если нужно что бы прокси ходил через другой прокси

First, you need to give Squid a parent cache with the cache_peer directive. 
Second, you need to tell Squid it can not connect directly to origin servers with never_direct. 
This is done with these configuration file lines:

```
cache_peer parentcache.foo.com parent 3128 0 no-query default
never_direct allow all
```
Note, with this configuration, if the parent cache fails or becomes unreachable, then every request will result in an error message.
In case you want to be able to use direct connections when all the parents go down you should use a different approach:

```
cache_peer parentcache.foo.com parent 3128 0 no-query
prefer_direct off
nonhierarchical_direct off
```
The default behavior of Squid in the absence of positive ICP, HTCP, etc replies is to connect to the origin server instead of using parents. The prefer_direct off directive tells Squid to try parents first before DNS listed servers.

Certain types of requests cannot be cached or are served faster going direct, and Squid is optimized to send them over direct connections by default. The nonhierarchical_direct off directive tells Squid to send these requests via the parent anyway.

/!\ The hierarchy_stoplist directive is another which will cause traffic to go DIRECT instead of to a peer. It should be removed completely from Squid-3.2 and later configurations if present.
