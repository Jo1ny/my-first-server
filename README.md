# Что нужно для запуска контейнера?

### 1. Создать рабочую директорию в которой будет храниться содержимое
	```bash
	mkdir ~/Название_директории

### 2. Перейти в рабочую директорию
	```bash
	cd ~/Название_директории

### 3. Инициализируй репозиторий в рабочей директории
	git init -b main

### 4. Внутри рабочей директории нужно 2 рабочих файла
	-'index.html' -статическая страница. то что nginx должен отправить на сервер
	-'Dockerfile' -инструкция сборки легковесного образа на базе Alpine Nginx

	ПРИМЕР СТРАНИЦЫ:
		<!DOCTYPE html>
		<html>
		<head>
			<meta charset="UTF-8">
			<title>Мой сервер</title>
		</head>
		<body style="background: #1e1e2e; color: #cdd6f4; font-family: sans-serif; text-align: center; padding-top: 50px;">
			<h1>Сервер работает!</h1>
			<p>Собрано своими руками с нуля.</p>
		</body>
		</html>

	ПРИМЕР DOCKERFILE:
		FROM nginx:alpine

		COPY index.html /usr/share/nginx/html/index.html

		EXPOSE 80

### 5. Сборка образа
	docker build -t название_твоего_образа:v1 .
	Точка в конце это контекст сборки(текущая директория)

### 6. Запуск контейнера
	docker run -d -p 127.0.0.1:8080:80 --name my-web название_твоего_контейнера:v1
	-d - запуск в фоновом режиме, чтобы не занимать терминал
	-p 127.0.0.1:8080:80 - проброс порта на loopback. так порт не висит и не светит наружу как 0.0.0.0

	docker ps   			# список запущенных контейнеров
	docker stop my-web		# остановить контейнер
	docker rm my-web		# удалить контейнер
	
	Важно: два разных контейнера нельзя повесить на один и тот же внешний порт хоста.

### Диагностика и отладка (Логи и вход внутрь)

#### Просмотр логов
```bash
docker logs my-web			# прочитать все накопленные логи
docker logs -f my-web		# просмотр логов в реальном времени (чтобы выйти, зажми Ctrl + C)

Логи показывают входящие HTTP запросы(IP клиента, статус ответа 200, 404 и т.д.) и ошибки сервера

### Интерактивный вход внутрь контейнера
```bash
docker exec -it my-web sh
exec			# выполнить команду внутри работающего контейнера
-it				# интерактивный режим(подключает твой теминал к контейнеру)
sh				# запуск оболочки shell(в Alpine Linux используется sh)

Для выхода пропиши exit

### Монтирование файлов (Bind Mount) и безопасность
Позволяет пробрасывать файлы с хоста внутрь контейнера без пересборки образа('docker build')

```bash
docker run -d \
	-p 127.0.0.1:8081:80 \
	-v $PWD/index.html:/usr/share/nginx/html/index.html:ro \	# -v <путь_на_хосте>:<путь_в_контейнере> - связывает файл на хосте с файлом в контейнере. Изменения на хосте сразу видны изнутри, а :ro устанавливает на контейнере только чтение в целях безопасности
	--name my-web \
	simple-web:v1

### Кастомизация Nginx и скрытие версии (Security Hardening)
По умолчанию Nginx отдает свое точную версию в HTTP-заголовках, что упрощает разведку для злоумышленников (Information Disclosure)

1. Создан конфиг `default.conf` с директивой `server_tokens off;`:
```nginx
server {
    listen 80;
    server_name localhost;

    server_tokens off; # скрывает версию Nginx из заголовков ответа

    location / {
        root /usr/share/nginx/html;
        index index.html;
    }
}

2.Запуск контейнера с монтированием конфига(текущий контейнер надо остановить и удалить через docker rm -f my-web)
```bash
docker run -d \
  -p 127.0.0.1:8081:80 \
  -v $PWD/index.html:/usr/share/nginx/html/index.html:ro \
  -v $PWD/nginx.conf:/etc/nginx/nginx.conf:ro \
  --name my-web \
  simple-web:v1

3. Проверяй результат через curl -I. Версия Nginx должна быть скрыта

#### Полная упаковка в образ (simple-web:v2)
Корневой конфиг Nginx и статика вшиты напрямую в образ.

1. `Dockerfile`:
```dockerfile
FROM nginx:alpine

# Заменяем главный конфиг Nginx
COPY nginx.conf /etc/nginx/nginx.conf

# Копируем статический сайт
COPY index.html /usr/share/nginx/html/index.html

EXPOSE 80

ВАЖНО! Если в файле есть events и http — это главный конфиг, его место строго в /etc/nginx/nginx.conf.
Если в файле только блок одного сайта server { ... } — это конфиг виртуального хоста, его кладут в /etc/nginx/conf.d/<имя>.conf.

2. Сборка и безопасный запуск
```bash
docker build -t simple-web:v2 .
docker run -d -p 127.0.0.1:8081:80 --name my-web simple-web:v2

3. Проверка скрытия версии веб-сервера
```bash
curl -I 127.0.0.1:8081
# Ожидаемый результат: заголовок "Server: nginx" без номеров версий