# Проектная работа 
## Тема проектной работы: Запуск веб-приложения под управлением Angie с реализацией защиты от DoS-атак и настройкой мониторинга в Grafana

![image](https://github.com/user-attachments/assets/5cb57591-7c54-4bb7-9cc7-69a3e7d04e06)


# Установка Zabbix 

Установку Zabbix выполняем по [инструкции] (https://www.zabbix.com/download?zabbix=7.2&os_distribution=ubuntu&os_version=24.04&components=server_frontend_agent&db=pgsql&ws=nginx)

## Краткий список команд 

### Установить репозиторий Zabbix
```
wget https://repo.zabbix.com/zabbix/7.2/release/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.2+ubuntu24.04_all.deb
dpkg -i zabbix-release_latest_7.2+ubuntu24.04_all.deb
apt update
```

### Установка Zabbix сервера, интерфейса, агента
```
apt install zabbix-server-pgsql zabbix-frontend-php php8.3-pgsql zabbix-nginx-conf zabbix-sql-scripts zabbix-agent
```

### Создать начальную базу данных
Убедитесь, что сервер базы данных запущен и работает.

Запустите следующую команду на хосте вашей базы данных.

```
sudo -u postgres createuser --pwprompt zabbix
sudo -u postgres createdb -O zabbix zabbix
```

### На сервере Zabbix импортируйте начальную схему и данные. Вам будет предложено ввести ваш новый пароль.

```
zcat /usr/share/zabbix/sql-scripts/postgresql/server.sql.gz | sudo -u zabbix psql zabbix
```

### Настройте базу данных для Zabbix сервера
Отредактируйте файл /etc/zabbix/zabbix_server.conf

```
DBPassword=password
```

### Настройка PHP для интерфейса Zabbix
Отредактируйте файл /etc/zabbix/nginx.conf, раскомментируйте и установите директивы «listen» и «server_name».

```
listen 8080;
server_name example.com;
```

### Запуск процессов Zabbix сервера и агента
Запустите процессы сервера и агента Zabbix и сделайте так, чтобы они запускались при загрузке системы.

```
systemctl restart zabbix-server zabbix-agent nginx php8.3-fpm
systemctl enable zabbix-server zabbix-agent nginx php8.3-fpm
```

# Миграция на Angie

## Проверка nginx 
```
nginx -V - покажет инфо по nginx

nginx -T - покажет полную текущую конфигурацию 

nginx -T | grep load_module - покажет загружаемые модули
```

## Установка angie
```
apt install angie angie-module-{name} - установит angie и желаемый модуль сразу 
```
```
apt install angie-modul-{name} - Устанавливает модули из репозитория Angie
```
```
systemctl status nginx - проверяет статус nginx
```
```
systemctl status angie - проверяет статус angie
```

### Рекомендуется отключить автозагрузку angie 
```
systemctl disable angie
```

### Конфиг angie 
```
cd /etc/angie
```
```
nano /etc/angie/angie.conf
```
### В конфиге нужно добавить в верхнем уровне контекста дополнительные модули (nginx -T | grep load_module)
```
angie -t - тест angie
```


### Перенос конфигов командой cp либо через mc, если он есть
```
/etc/nginx   		/etc/angie 

/sites-available
/sites-enabled
/snippets
/ssl 
dhparam
dhparam.pem
fastcgi.conf - если нужен (сравнить)
mime.types - если нужен (сравнить)
proxy_params - если нужен (сравнить)
scgi_params - если нужен (сравнить)
uwsgi_params - если нужен (сравнить)

nginx.conf - сравнить
```

### По итогу для миграции перенес:
```
/conf.d - каталог с zabbix.conf
/sites-available
/sites-enabled
/snippets
/ssl 
dhparam
dhparam.pem
fastcgi.conf
mime.types
proxy_params
scgi_params
uwsgi_params
```
### Для сравнения используем 
```
diff /etc/nginx/fastcgi.conf /etc/angie/fastcgi.conf
```

### Сравниваем два конфига nginx.conf и angie.conf и переносим то что должно быть перенесено. 

Не забываем про пути к файлам nginx которые упоменаются в перенесенных настройках конфига
```
grep -rn '.nginx' /etc/angie
```
### Что бы заменить все можно использовать команду 
```
find /etc/angie -type f -name '*.conf' -exec sed --follow-symlinks -i 's|/nginx|/angie|g' {} \;
```

### В angie.conf из nginx.conf перенес: 
```
user  www-data;
```
```
proxy_cache_valid 1m;
proxy_cache_key $scheme$host$request_uri;
proxy_cache_path /var/www/cache levels=1:2 keys_zone=one:10m inactive=48h max_size=800m;
```
```
access_log  /var/log/angie/access.log  main;
error_log /var/log/angie/error.log;
```
```
gzip  on;
gzip_vary on;
gzip_proxied any;
gzip_comp_level 6;
gzip_buffers 16 8k;
gzip_http_version 1.1;
gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/ja>
```
```
include /etc/angie/conf.d/*.conf;
include /etc/angie/sites-enabled/*;
```

### Далее идем в cd /etc/angie/sites-enabled 
```
ll
```
### И обращаем внимание на /etc/nginx/sites-available/default
```
total 8
drwxr-xr-x 2 root root 4096 Oct 10 13:22 ./
drwxr-xr-x 8 root root 4096 Oct 13 13:04 ../
lrwxrwxrwx 1 root root   34 Oct 10 13:22 default -> /etc/nginx/sites-available/default
root@ad-ag-zbx-01:/etc/angie/sites-enabled#
```
### Используем 
```
find /etc/angie/sites-enabled/* -type l -printf 'ln -nsf "$(readlink "%p" | sed s!/etc/nginx/sites-available!/etc/angie/sites-available!)" "$(echo "%p" | sed s!/etc/nginx/sites-available!/etc/angie/sites-available!)"\n' > script.sh
```
```
ll - проверяем 
```
```
chmod +x script.sh - добавляем права 
```
```
./script.sh - запускаем скрипт
```
```
ll - проверяем
```

### Тестирование конфигурации
```
sudo angie -t
```
### По результатам теста получил 
```
root@ad-ag-zbx-01:/etc/angie# angie -t
angie: the configuration file /etc/angie/angie.conf syntax is ok
angie: configuration file /etc/angie/angie.conf test is successful
```

## Переключение на Angie
```
sudo systemctl stop nginx && sudo systemctl start angie
```

### Включение автозагрузки
```
sudo systemctl disable nginx
```
```
sudo systemctl enable angie
```
### Проверяем. В моем случае Zabbix (http://zabbix6.lan/), который был ранее установлен и работал на nginx запустился без проблем. 
![Screenshot_2](https://github.com/user-attachments/assets/a90a1121-a52a-4845-b357-0c3dcc054494)

```
systemctl mask nginx - замаскирует nginx и обезапасит от случайного запуска 
```

# Оптимизация производительности

## Серверное кэширование
--------------------------------------------------------------------------------------------------------
### Добавить в angie.conf в контекст http строки:
-----------------------------------------------------
```
proxy_cache_valid 1m;
proxy_cache_key $scheme$host$request_uri;
proxy_cache_path /var/www/cache levels=1:2 keys_zone=one:10m inactive=48h max_size=800m;
```
-----------------------------------------------------
### Добавим location строки:
-----------------------------------------------------
Кэширование статических файлов:
```
                 location ~* \.(jpg|jpeg|png|gif|ico|css|js|woff|woff2|ttf|svg|eot|otf|ttc|mp4|avi|webm|mkv)$ {
                    # Устанавливаем срок действия для кэширования
                         expires 30d;
                    # Отключаем логирование запросов для статических файлов
                         access_log off;
                         add_header Cache-Control "public";
                 }
```
Кэширование HTML:
```
                 location ~* \.(html|htm)$ {
                    # Включаем кэширование
                         proxy_cache one;
                    # Устанавливаем срок действия кэша для успешных запросов
                         proxy_cache_valid 200 1h;
                         proxy_cache_lock on;
                         proxy_cache_min_uses 2;
                         proxy_ignore_headers "Cache-Control" "Expires";
                         proxy_cache_use_stale updating error timeout invalid_header http_500 http_502 http_503 http_504;
                    # Для проверки статуса кэша
                         add_header X-Cache-Status $upstream_cache_status;
                }
```
-----------------------------------------------------
### Проверим конфиг Angie:
-----------------------------------------------------
```
# angie -t && angie -s reload
```
-----------------------------------------------------
### Получаем ответ ОК
```
angie: the configuration file /etc/angie/angie.conf syntax is ok
angie: configuration file /etc/angie/angie.conf test is successful
```
### Проверяем
-----------------------------------------------------
### До настроек:
![Screenshot_8](https://github.com/user-attachments/assets/6d4f2509-d915-483a-b73f-8d390ffa0d9a)
![Screenshot_9](https://github.com/user-attachments/assets/71354cc1-d2ef-4852-b504-3c4615f8de60)
### После настроек:
![Screenshot_10](https://github.com/user-attachments/assets/e45ec022-d41f-40e3-956f-dcac20a55ed2)
![Screenshot_11](https://github.com/user-attachments/assets/2a90303a-b21a-41e0-9232-7daa9eaab089)
-----------------------------------------------------
### Особо ничего не поменялось, но у нас и сайт пустой. 
--------------------------------------------------------------------------------------------------------
## Клиентская оптимизация
--------------------------------------------------------------------------------------------------------
### Сжатие текстовых ресурсов
-----------------------------------------------------
### Добавляем в angie.conf в контекст http строки:
```
        gzip  on;
        gzip_static on;
        gzip_vary on;
        gzip_proxied any;
        gzip_comp_level 6;
        gzip_min_length 1000;
        gzip_buffers 16 8k;
        gzip_http_version 1.1;
        gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/ja>
```

# Выпуск серификата и переход на HTTPS

### Предворительно на reg.ru приобрели домен admin-angie.ru

### После чего воспользовался командой 
```
sudo certbot certonly --manual --preferred-challenges dns -d admin-angie.ru
```
### для получения TXT - записи которую мы добавим в настройки DNS на reg.ru нашего домена. 
### Получаем запись вида:

```
Please deploy a DNS TXT record under the name:
_acme-challenge.admin-angie.ru
with the following value:
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### Добавляем TXT запись и ждем, паралельно периодически проверяя вступленее в силу новых настроек с помощью команды:

```
dig TXT _acme-challenge.admin-angie.ru
```
### Обычно занимает минут 10-15. 

### Получаем:

```
root@ad-ag-zbx-01:/etc/angie# dig TXT _acme-challenge.admin-angie.ru

; <<>> DiG 9.18.28-0ubuntu0.24.04.1-Ubuntu <<>> TXT _acme-challenge.admin-angie.ru
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 29611
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;_acme-challenge.admin-angie.ru.        IN      TXT

;; ANSWER SECTION:
_acme-challenge.admin-angie.ru. 300 IN  TXT     "_VEb2XECwO6L1WcyuSY9y4QDOKMIe27lf7DyeItqV7c"

;; Query time: 71 msec
;; SERVER: 127.0.0.53#53(127.0.0.53) (UDP)
;; WHEN: Fri Nov 29 14:23:02 UTC 2024
;; MSG SIZE  rcvd: 115

```
### Как только изменения вступили в силу, возвращаемся к Certbot и продолжаем выпуск сертификата. 

### Если все сделано правильно, Certbot должен завершить процесс и выдать сертификат. Сертификат будет сохранен по пути /etc/letsencrypt/live/admin-angie.ru/.

### Далее начинаем править конфиг. В /etc/angie/http/static-site.conf добавим 

```
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECD>
ssl_prefer_server_ciphers off;
ssl_dhparam /etc/angie/dhparam.pem;
ssl_session_timeout 1d;
ssl_session_cache shared:MozSSL:10m;
```
### (Данные берем от сюда https://ssl-config.mozilla.org/)

### Добавим путь к сертификатам 

```
        ssl_certificate /etc/letsencrypt/live/admin-angie.ru/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/admin-angie.ru/privkey.pem;
```

### Поменяем начало нащего сервера, что бы включить http2 и http3 
```
server {
    listen 443 ssl reuseport;
    listen 443 quic reuseport;
    server_name admin-angie.ru;
    http2 on;
    http3 on;
```

### Поправим во втором сервере перадресацию 

```
server {
    listen 80;
    server_name admin-angie.ru  www.admin-angie.ru;
    return 301 https://admin-angie.ru$request_uri;
}
```

### и добавис заголовки в location

```
    location / {
        add_header Strict-Transport-Security "max-age=63072000" always;
        add_header Alt-Svc 'h3=":443"; ma=86400';
        index index.html index.htm;
        try_files $uri $uri/ =404;
    }
```
### проверяем angie

```
angie -t
```
### Теперь проверим работу сайта 

![image](https://github.com/user-attachments/assets/6e622fdc-afd0-4b6b-b3e0-3aaeb750d027)

### Видим что мы успешно перешли на https

# Балансировка HTTP.
-----------------------------------------------------------------------------

## Установим docker-compose

-----------------------------------------------------------------------------
```
apt-get update
sudo apt install -y docker-compose-plugin
```
-----------------------------------------------------------------------------

### Проверим версию docker-compose

-----------------------------------------------------------------------------
```
docker compose version
```
-----------------------------------------------------------------------------

### Создадим файл docker-compose.yml

-----------------------------------------------------------------------------
```
nano docker-compose.yml
```
-----------------------------------------------------------------------------

### Проверяем синтаксис файла 

-----------------------------------------------------------------------------
```
docker compose config
```
-----------------------------------------------------------------------------

### Запускаем контейнеры 

-----------------------------------------------------------------------------
```
docker compose up -d
```
-----------------------------------------------------------------------------

![docker](https://github.com/user-attachments/assets/ce36c627-f7cc-471d-90c5-580971357307)


### У меня почему то неустановлен пакет angie-console-light, поэтому установим его.

-----------------------------------------------------------------------------
```
sudo apt update
apt install angie-console-light
```
-----------------------------------------------------------------------------
## Настройка балансировки.
-----------------------------------------------------------------------------

### Равномерная балансировка round robin
-----------------------------------------------------------------------------

### Добавим секцию upstream в конфиг, и в location /console/ что бы можно было заходить в консоль angie 

```
upstream admin_angie {
    zone upstream-backend 256k;
    server 192.168.0.253:9000 sid=white;
    server 192.168.0.253:9001 sid=blue;
    server 192.168.0.253:9002 sid=green;
    server 192.168.0.253:9003 sid=gold;
}

server {
    listen 80;
    listen 443 ssl;
    listen 443 quic;
	
.....

location /status/ {
        api /status/;
        api_config_files on;

}

    location /console/ {
        allow all;

        alias /usr/share/angie-console-light/html/;
                index index.html;

        location /console/api/ {
        api /status/;

        }


}
```
-----------------------------------------------------------------------------

### Заходим по адресу https://admin-angie.ru/console/ и проверяем 

-----------------------------------------------------------------------------
![Hash](https://github.com/user-attachments/assets/41b7e763-ab64-4a8d-90f8-03d0c792b434)
-----------------------------------------------------------------------------

## Балансировка по хэшу с использованием переменных

-----------------------------------------------------------------------------
### Добавим в секцию upstream строку:

-----------------------------------------------------------------------------
```
......
hash $scheme$request_uri;
......
```
-----------------------------------------------------------------------------

### Теперь проверим и убедимся, что мы попадаем на разные бэкенды в зависимости от строки запроса

-----------------------------------------------------------------------------

## Произвольная балансировка (random)

-----------------------------------------------------------------------------

### Добавим в секцию upstream random вместо строки hash.

-----------------------------------------------------------------------------
![Random](https://github.com/user-attachments/assets/5d42b14a-57cb-4a00-89c3-f24295a88c19)
-----------------------------------------------------------------------------

### Резервный бэкенд и отключение бэкендов

-----------------------------------------------------------------------------

### Параметр backup нельзя использовать совместно с методами балансировки нагрузки hash, ip_hash и random, поэтому вернём конфигурацию Round Robin 
### Теперь назначим blue бэкенд резервным:

-----------------------------------------------------------------------------
```
server 192.168.0.253:9001 sid=blue backup;
```
-----------------------------------------------------------------------------

### Видим, что сервер помечен как резервный и запросы на него не поступают:

-----------------------------------------------------------------------------
![backup](https://github.com/user-attachments/assets/da1764cf-0768-4f78-8339-1de815847b57)
-----------------------------------------------------------------------------

### Попробуем погасить один их основных бэкендов:

-----------------------------------------------------------------------------
```
docker stop debug-green
```
-----------------------------------------------------------------------------

### В консоли видим сервер в состоянии Failed, запросы продолжают идти к двум оставшимся серверам:

-----------------------------------------------------------------------------
![backup and stop debug_2](https://github.com/user-attachments/assets/752607b9-8539-4aa3-a74d-30410064f0a9)
-----------------------------------------------------------------------------

### Погасим остальные два бэкенда:

-----------------------------------------------------------------------------
```
docker stop debug-gold debug-white
```
-----------------------------------------------------------------------------

### Резервный сервер включился в работу, запросы пошли на него.

-----------------------------------------------------------------------------
![backup and stop debug_3](https://github.com/user-attachments/assets/cfc04535-1aa4-4675-8b13-83e921d25a3b)
-----------------------------------------------------------------------------

### Вернём обратно сервера:

-----------------------------------------------------------------------------
```
docker start debug-gold debug-white debug-green
```
-----------------------------------------------------------------------------

### Резервный сервер снова не задействован, все запросы пошли на запущенные сервера:

-----------------------------------------------------------------------------
![backup and stop debug_4](https://github.com/user-attachments/assets/a8337770-0d7e-4022-89b3-314f54ae0a1b)
-----------------------------------------------------------------------------

# Создание зон лимита конектов. 
-----------------------------------------------------------------------------

### В контексте http пропишем наши зоны. Помним что название зон должны быть уникальны 

-------------------------------------------------
```
http {
...
        #Лимит подключений
        limit_conn_zone $binary_remote_addr zone=perip:10m;
		
        #Лимит по параметру server_name
        limit_conn_zone $server_name zone=perserver:10m;
		
        #Лимит частоты запросов
        limit_req_zone $binary_remote_addr zone=lone:10m rate=1r/s;


...
}
```
-------------------------------------------------

### А в блоке сервер включим работу зон. limit_req прописываем в location / что бы он не задел console angie.  

-------------------------------------------------
```
server {
...

    #Включаем статус зоны для отслеживания в console angie
    status_zone _;
	
    #Включаем и задаем лимиты по количеству подключений
    limit_conn perip 10;
    limit_conn perserver 100;
	
    #Задаем лимит частоты запросов
	 location / {
		...
        limit_req zone=lone burst=5;
		...
	}
...
}
```
-------------------------------------------------

## Теперь прверим работу. 
### Сначала проверим работу зону perip
### Отправим запросов на несколько паралельных подключений с помощью AB

-------------------------------------------------
```
ab -n 200 -c 8 -l -k -H "Accept-Encoding: gzip,deflate,br" https://admin-angie.ru/
```
-------------------------------------------------

### и проверим в логах /var/log/angie/error.log

![Screenshot_3](https://github.com/user-attachments/assets/9037aa01-3ab0-4bbe-83bb-5ef7eea8157e)


### И также можем увидеть изменения в консоли angie

![Screenshot_4](https://github.com/user-attachments/assets/7375a542-27ed-4e4c-ac07-cb35685eb207)

-------------------------------------------------
### Теперь проверим работу зоны lone, контролирующую частоту запросов 

![Screenshot_2](https://github.com/user-attachments/assets/a91c25cb-e972-416e-87ca-d38cccc6fd21)



![Screenshot_1](https://github.com/user-attachments/assets/457b20e6-b56e-46d2-a685-68840e423e1c)


![Screenshot_6](https://github.com/user-attachments/assets/89030d5e-06f2-44c3-bcea-f80c8466d155)

-------------------------------------------------
-----------------------------------------------------------------------------
## Аунтетификация
-----------------------------------------------------------------------------

### Восполюзуемся htpasswd, из пакета Apache, для создания новго пользователя и пароля

-------------------------------------------------
```
htpasswd -c /etc/angie/htpasswd newuser
```
-------------------------------------------------

### И в результате получим файлик в которому будет содарежаться наш пользователь 

-------------------------------------------------
```
root@ad-ag-zbx-01:~# cat /etc/angie/htpasswd
newuser:$apr1$1jb6cM0x$n6WEDaoW4CYq3rnRKL/3n1
```
-------------------------------------------------

### Далее в нашем конфиге пропишем аутентификацию на сам сайт

-------------------------------------------------
```
auth_basic "Identify yourself!";
auth_basic_user_file /etc/angie/htpasswd;
```
-------------------------------------------------

### Перезапускаем angie и проверяем аутентификацию на сайте 

-------------------------------------------------
![photo_2024-12-25_15-55-35](https://github.com/user-attachments/assets/3b5966e7-fca4-4b74-9e27-e64ef3bf9248)

![Screenshot_5](https://github.com/user-attachments/assets/51b40fc4-c1df-45f1-ab39-904d264c6f8a)

-------------------------------------------------
-----------------------------------------------------------------------------
### Аунтетификация с доступом по IP
-----------------------------------------------------------------------------

### Для этого пропишем в конфиге 

-------------------------------------------------
```
satisfy any;
#allow 192.168.0.0/24;
```
-------------------------------------------------

### Перезапускаем angie и проверяем аутентификацию через страницу инкогнито в браузере. 

-----------------------------------------------------------------------------
## Fail2ban
-----------------------------------------------------------------------------

### После установки пакета fail2ban скопируем файл jail.conf в файл jail.local и в нем пропишем следующее 

-------------------------------------------------
```
[nginx-limit-req]
port    = http,https  
enabled = true
filter = nginx-limit-req
action = iptables-multiport[name=ReqLimit, port="http,https", protocol=tcp]
logpath = /var/log/angie/*error.log
findtime = 600
bantime = 7200
maxretry = 4
```
-------------------------------------------------

### Также можем прописать блокировку при некорректной аутентификации

-------------------------------------------------
```
[nginx-http-auth]
# mode = normal
port    = http,https
enabled = true
findtime = 10
bantime = 30
maxretry = 3
logpath = /var/log/angie/*error.log

```
-------------------------------------------------

### Проверим статус fail2ban

-------------------------------------------------
```
root@ad-ag-zbx-01:/etc/angie# fail2ban-client status
Status
|- Number of jail:      3
`- Jail list:   nginx-http-auth, nginx-limit-req, sshd
```
-------------------------------------------------

### Видим, что у нас включены nginx-http-auth, nginx-limit-req, sshd. (sshd включен по умолчанию)
### Теперь проверим статус nginx-limit-req

-------------------------------------------------
```
root@ad-ag-zbx-01:/etc/angie# fail2ban-client status nginx-limit-req
Status for the jail: nginx-limit-req
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     0
|  `- File list:        /var/log/angie/error.log
`- Actions
   |- Currently banned: 0
   |- Total banned:     0
   `- Banned IP list:
```
-------------------------------------------------

### Видим что срабатываний нет и никто не забанен. 
### Попробуем снова отправить запросы. 

-------------------------------------------------
```
ab -n 200 -c 8 -l -k -H "Accept-Encoding: gzip,deflate,br" https://admin-angie.ru/
```
-------------------------------------------------

### И проверим статус nginx-limit-req. 

-------------------------------------------------
```
root@ad-ag-zbx-01:/etc/angie# fail2ban-client status nginx-limit-req
Status for the jail: nginx-limit-req
|- Filter
|  |- Currently failed: 1
|  |- Total failed:     1994
|  `- File list:        /var/log/angie/error.log
`- Actions
   |- Currently banned: 1
   |- Total banned:     1
   `- Banned IP list:   192.168.0.253
```
-------------------------------------------------

### Видим что нас забанели (Banned IP list:   192.168.0.253)

### Теперь разбаним наш IP 

-------------------------------------------------
```
fail2ban-client set nginx-limit-req unbanip 192.168.0.253
```
-------------------------------------------------

# Установка мониторига Grafana

## Prometheus

### Для начала установим Prometheus, так как именно с его помощью мы будем интегрировать метрики из Console Angie.

```
apt install prometheus 
```
### Перезагружаем prometheus

```
systemctl restart prometheus
```
### Prometheus по умолчанию доступен по порту 9090. В нашем случае http://192.168.0.253:9090/
### Далее заходим в /etc/prometheus.yml и добавляем следующее 

```
# Scrape Angie metrics
  - job_name: "angie"
    scrape_interval: 15s
    metrics_path: "/p8s"
    static_configs:
      - targets: ["localhost:8080"]
```

### Теперь установим Grafana

```
apt install grafana
```
### Grafana по умолчанию доступен по порту 3000. В нашем случае http://192.168.0.253:3000/
![image](https://github.com/user-attachments/assets/c541bebb-8a10-4a81-9f87-19aa8e5fb7f4)

### Переходим в http://192.168.0.253:3000/ , заходим в Connections -> Data sources и добавляем Prometheus. Адрес указываем http://192.168.0.253:9090/
![image](https://github.com/user-attachments/assets/fa28a605-8501-4331-ad80-b4480daaca33)

## Добавляем Dashboards Node Exporter Full и Angie
### Переходим в Dashboards, нажимаем кнопку NEW/new dachboards
![image](https://github.com/user-attachments/assets/a3008787-bb93-4a5b-b7ff-7e02e5fbf1e5)

### Переходим на сайт https://grafana.com/grafana/dashboards/20719-angie-dashboard/ скачиваем Download JSON
![image](https://github.com/user-attachments/assets/5d53c104-6498-471d-a9fe-7692435812c0)

### В поле Import via dashboard JSON model вводим содержимое ранее скаченого файла JSON
![image](https://github.com/user-attachments/assets/e6ec7680-d967-48d8-9238-a1b995197135)

### Для Node Exporter делаем то же самое файл JSON скчиваем отсюда https://grafana.com/grafana/dashboards/1860-node-exporter-full/

### В итоге получаем рабочие dachboards по мниторингу angie и ресурсов сервера

![image](https://github.com/user-attachments/assets/fe0fcf78-ff12-43aa-9420-7957818cfd34)

![image](https://github.com/user-attachments/assets/df7429a8-f3ad-410d-b788-4e25a37da4df)

