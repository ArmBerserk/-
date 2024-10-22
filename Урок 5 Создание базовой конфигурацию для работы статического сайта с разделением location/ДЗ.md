
Все работы выполнены в Ubuntu 24.04
--------------------------------------------------------------------------------------------------------
```
root@ad-ag-zbx-01:/etc/angie/http.d# lsb_release -a
No LSB modules are available.
Distributor ID: Ubuntu
Description:    Ubuntu 24.04 LTS
Release:        24.04
Codename:       noble
root@ad-ag-zbx-01:/etc/angie/http.d#
```
```
root@ad-ag-zbx-01:/etc/angie/http.d# angie -v
Angie version: Angie/1.7.0
```
--------------------------------------------------------------------------------------------------------

Скачиваем архив с сайтом 
```
wget https://cdn.otus.ru/media/public/96/c1/static_site-252831-96c1e2.zip
```
--------------------------------------------------------------------------------------------------------
Распаковываем архив в папку /var/www/static-site и изменим владельца и группу на angie.
```
sudo mkdir /var/www
sudo unzip static_site-252831-96c1e2.zip -d /var/www/static-site
sudo chown -R angie:angie /var/www/
```
--------------------------------------------------------------------------------------------------------
В папке /etc/angie/http.d создадим файл static-site.conf 
```
nano /etc/angie/http.d/static-site.conf
```
И вносим следующие параметры:

---------------------------------------
```
server {
    listen 80;
    location / {
        root /var/www/static-site;
        index index.html;
    }
}
```
---------------------------------------

--------------------------------------------------------------------------------------------------------
Проверяем конфиг
```
angie -t
```
----------------------------------------------------------------------
Результат
```
angie: the configuration file /etc/angie/angie.conf syntax is ok
angie: configuration file /etc/angie/angie.conf test is successful
```
----------------------------------------------------------------------
Если все ОК то рестартим angie
```
systemctl restart angie
```
--------------------------------------------------------------------------------------------------------
Проверяем работу сайта на 80 порту 
```
# curl -I localhost:80
HTTP/1.1 403 Forbidden
Server: Angie/1.7.0
Date: Tue, 22 Oct 2024 12:30:49 GMT
Content-Type: text/html
Content-Length: 152
Connection: keep-alive
Vary: Accept-Encoding
```
--------------------------------------------------------------------------------------------------------

На рабочем компьютере в файл C:\Windows\System32\drivers\etc\hosts строку:

192.168.0.253  admin-angie.local www.admin-angie.local

В конфиге /var/www/static-site добавим:
----------------------------------------
    listen 80;
    server_name otus-angie.local;
----------------------------------------
--------------------------------------------------------------------------------------------------------
Теперь с рабочего компа можно открыть сайт по адресу http://admin-angie.local 

![Screenshot_1](https://github.com/user-attachments/assets/e525fe99-2f85-460a-be40-4e26e18d3142)

--------------------------------------------------------------------------------------------------------
Добавим в конфиг map
```
map $msie $cache_control {
    default "max-age=31536000, public, no-transform, immutable";
    "1"     "max-age=31536000, private, no-transform, immutable";
}
```
--------------------------------------------------------------------------------------------------------
Добавим location для assets и error

----------------------------------------------------------
    location /assets {
        add_header Cache-Control $cache_control;
    }

    location /error {
        add_header Cache-Control $cache_control;
    }
----------------------------------------------------------

И location c регулярным выражением для отдачи картинок

----------------------------------------------------------
    location ~* \.(jpg|jpeg|png|gif)$ {
        valid_referers none blocked admin-angie.local;
        if ($invalid_referer) {
           return 403;
        }
		}
----------------------------------------------------------
--------------------------------------------------------------------------------------------------------

Добавляем обработку ошибки 404
```
error_page 404 /error/index.html;
```
--------------------------------------------------------------------------------------------------------
