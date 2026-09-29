FROM nginx:alpine

# Заменяем главный корневой конфиг Nginx целиком
COPY nginx.conf /etc/nginx/nginx.conf

# Копируем статику сайта и страницу ошибки
COPY index.html /usr/share/nginx/html/index.html
COPY 404.html /usr/share/nginx/html/404.html

EXPOSE 80
