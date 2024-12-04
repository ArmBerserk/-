# Slow start
wrk -t 1 -c 1 -d 30s http://192.168.122.141

upstream backend {
    zone upstream-backend 256k;
    server 127.0.0.1:9000 sid=white slow_start=120s;
    server 127.0.0.1:9001 sid=blue slow_start=120s;
    server 127.0.0.1:9002 sid=green slow_start=120s;
    server 127.0.0.1:9003 sid=gold slow_start=120s;
}

docker stop debug-blue
docker start debug-blue

# Sticky route
upstream backend {
    zone upstream-backend 256k;
    server 127.0.0.1:9000 weight=4 sid=white;
    server 127.0.0.1:9001 sid=blue;
    server 127.0.0.1:9002 sid=green;
    server 127.0.0.1:9003 weight=4 fail_timeout=5s sid=gold;
    sticky route $arg_route;
    sticky_strict on;
}

http://ip?route=white
http://ip?route=green

# Keepalive
wrk -t 4 -c 8 -d 30s http://192.168.122.141
http://192.168.122.141:8080/server-status
upstream backend {
    zone upstream-backend 256k;
    #hash $request_uri;
    #random;
    server 127.0.0.1:8080 weight=2;
    server 127.0.0.1:8081;
    server 127.0.0.1:8082;
    keepalive 16;
    keepalive_requests 1000;
    keepalive_time 1h;
    keepalive_timeout 120s;
}

# TCP balance - MySQL R/W split
upstream mysql_master {
    server 127.0.0.1:3307;
    zone tcp_mem 64k;
}

upstream mysql_slave {
    server 127.0.0.1:3308;
    zone tcp_mem 64k;
}

server {
    listen 6306;
    proxy_pass mysql_master;
}

server {
    listen 6307;
    proxy_pass mysql_slave;
}
################################
mysql -P 6306 -h 127.0.0.1 -uroot -pNykArNq1

mysql -P 6307 -h 127.0.0.1 -uroot -pNykArNq1

# Limit conn for stream
# angie.conf
limit_conn_zone $binary_remote_addr zone=addr:10m;
# Server
limit_conn           addr 1;
limit_conn_log_level error;
