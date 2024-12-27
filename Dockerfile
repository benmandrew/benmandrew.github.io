FROM nginx:alpine

COPY nginx.conf /etc/nginx/nginx.conf
COPY _site /usr/share/nginx/html
