FROM nginx:alpine

# Заменяем главный корневой конфиг Nginx целиком
COPY nginx.conf /etc/nginx/nginx.conf

# Копируем статику сайта
COPY index.html /usr/share/nginx/html/index.html

EXPOSE 80
