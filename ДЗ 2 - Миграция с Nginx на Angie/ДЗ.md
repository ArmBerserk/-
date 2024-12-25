Проверка nginx 
```
nginx -V - покажет инфо по nginx

nginx -T - покажет полную текущую конфигурацию 

nginx -T | grep load_module - покажет загружаемые модули
```

Установка angie
```
apt install angie angie-module-{name} - установит angie и желаемый модуль сразу 
```
```
apt install angie-modul-{name} - Устанавливает модули из репозитория Angie
```
```
sistemctl status nginx - проверяет статус nginx
```
```
sistemctl status angie - проверяет статус angie
```

Рекомендуется отключить автозагрузку angie 
```
sistemctl disable angie
```

Конфиг angie 
```
cd /etc/angie
```
```
nano /etc/angie/angie.conf
```
В конфиге нужно добавить в верхнем уровне контекста дополнительные модули (nginx -T | grep load_module)
```
angie -t - тест angie
```


Перенос конфигов командой cp либо через mc, если он есть
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

По итогу для миграции перенес:
```
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
Для сравнения использем 
```
diff /etc/nginx/fastcgi.conf /etc/angie/fastcgi.conf
```

Сравниваем два конфика nginx.conf и angie.conf и переносим то что должно быть перенесено. 

Не забываем про пути к файлам nginx которые упоменаются в перенесенных настройках конфига
```
grep -rn '.nginx' /etc/angie
```
Что бы заменить все можно использовать команду 
```
find /etc/angie -type f -name '*.conf' -exec sed --follow-symlinks -i 's|/nginx|/angie|g' {} \;
```

В angie.conf из nginx.conf перенес: 
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

Далее идем в cd /etc/angie/sites-enabled 
```
ll
```
И обращаем внимание на /etc/nginx/sites-available/default
```
total 8
drwxr-xr-x 2 root root 4096 Oct 10 13:22 ./
drwxr-xr-x 8 root root 4096 Oct 13 13:04 ../
lrwxrwxrwx 1 root root   34 Oct 10 13:22 default -> /etc/nginx/sites-available/default
root@ad-ag-zbx-01:/etc/angie/sites-enabled#
```
Используем 
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

Тестирование конфигурации
```
sudo angie -t
```
По результатам теста получил 
```
root@ad-ag-zbx-01:/etc/angie# angie -t
angie: the configuration file /etc/angie/angie.conf syntax is ok
angie: configuration file /etc/angie/angie.conf test is successful
```

Переключение на Angie
```
sudo systemctl stop nginx && sudo systemctl start angie
```

Включение автозагрузки
```
sudo systemctl disable nginx
```
```
sudo systemctl enable angie
```
Проверяем. В моем случае Zabbix (http://zabbix6.lan/), который был ранее установлен и работал на nginx запустился без проблем. 
![Screenshot_2](https://github.com/user-attachments/assets/a90a1121-a52a-4845-b357-0c3dcc054494)

```
systemctl mask nginx - замаскирует nginx и обезапасит от случайного запуска 
```
```
root@ad-ag-zbx-01:/etc/angie# systemctl status angie
● angie.service - Angie - high performance web server
     Loaded: loaded (/usr/lib/systemd/system/angie.service; enabled; preset: enabled)
     Active: active (running) since Wed 2024-10-16 13:37:09 UTC; 40min ago
       Docs: https://angie.software/en/
    Process: 2253 ExecStart=/usr/sbin/angie -c /etc/angie/angie.conf (code=exited, status=0/SUCCESS)
   Main PID: 2257 (angie)
      Tasks: 4 (limit: 9445)
     Memory: 58.9M (peak: 59.7M)
        CPU: 208ms
     CGroup: /system.slice/angie.service
             ├─2257 "angie: master process v1.7.0 #1 [/usr/sbin/angie -c /etc/angie/angie.conf]"
             ├─2258 "angie: worker process #1"
             ├─2259 "angie: worker process #1"
             └─2260 "angie: cache manager process #1"

Oct 16 13:37:09 ad-ag-zbx-01 systemd[1]: Starting angie.service - Angie - high performance web server...
Oct 16 13:37:09 ad-ag-zbx-01 systemd[1]: Started angie.service - Angie - high performance web server.


root@ad-ag-zbx-01:/etc/angie# systemctl status nginx
○ nginx.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; preset: enabled)
     Active: inactive (dead)
       Docs: man:nginx(8)
```


--------------------------------------------------------------------------------------------------------

Миграциā docker-контейнеров

● Меняем в командах docker run образ на Angie
● Работа с конфигами по аналогии с пакетами
● Варианты образов: minimal (без модулей) и обычные (список пакетов)
● В docker-compose.yml также меняем образ
● Восстановление команды docker run:
```
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock:ro \
 assaflavie/runlike pmm-server
 ```
● Чтобы выяснить настройки контейнера:

docker inspect {ID|name}

● Запуск нового контейнера:
```
docker stop nginx && docker run --name angie …
docker rm nginx
```
Сборка docker-образа

● Формируем свой Dockerfile
● Собираем образ
```
docker build -t myangie .
```
● Запускаем контейнер
```
docker run --rm --name myangie -v /var/www:/usr/share/angie/html:ro \
 -v $(pwd)/angie.conf:/etc/angie/angie.conf:ro -p 8080:80 -d myangie
```
