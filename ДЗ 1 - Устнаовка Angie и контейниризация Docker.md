Устанавливаем вспомогательные пакеты для подключения репозитория Angie:
```
sudo apt-get update
sudo apt-get install -y ca-certificates curl
```
Скачиваем открытый ключ репозитория Angie:
```
sudo curl -o /etc/apt/trusted.gpg.d/angie-signing.gpg \
            https://angie.software/keys/angie-signing.gpg
```			
Подключаем репозиторий Angie:
```
echo "deb https://download.angie.software/angie/$(. /etc/os-release && echo "$ID/$VERSION_ID $VERSION_CODENAME") main" \
    | sudo tee /etc/apt/sources.list.d/angie.list > /dev/null
```	
Обновляем индексы репозиториев:
```
sudo apt-get update
```
Устанавливаем пакет Angie:
```
sudo apt-get install -y angie
```
Устанавливаем docker:
```
apt install docker.io
```
Создаем контейнер :
```
docker run --name angie -v /var/www/html:/usr/share/angie/html:ro -p 8800:80 -d docker.angie.software/angie:1.7.0-alpine
```
Копируем конфиг:
```
docker cp angie:/etc/angie/ /home/adminangie/angie/
```
Переходит в каталог со скопированым конфигом и проверяем с помощью коменда ll:
```
cd /home/adminangie/angie/angie/
```
Далее можем удалять контуенер angie:
```
docker rm -f angie
```
Тперь можем создать новый контейнер и сразу импортировать копированные настройки:
```
docker run --name angie -v /var/www/html:/usr/share/angie/html:ro -v /home/adminangie/angie/angie:/etc/angie:ro -p 8800:80 -d docker.angie.software/angie:1.7.0-alpine
```
Установка дополнительного модуля

В данном случае (angie-module-image-filter) добавляет преобразования изображений в форматах JPEG, GIF, PNG и WebP.
```
sudo apt-get install -y angie-module-image-filter 
```
Запуск angie из контейнера 

Проверяем работает ли на контейнер с angie
```
curl localhost:8800
```
Проваливаемся во внутрь котейнера 
```
docker exec -ti angie ash
```
Для проверки работы контейнера можно использовать команду 
```
docker ps
```
