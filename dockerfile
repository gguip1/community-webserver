FROM nginx:alpine

COPY nginx.conf /etc/nginx/nginx.conf
COPY conf.d/*.conf /etc/nginx/conf.d

EXPOSE 80
EXPOSE 443
