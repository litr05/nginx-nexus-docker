FROM nginx:alpine

RUN mkdir -p /etc/nginx/external

COPY nexus*.* /etc/nginx/external/

COPY nginx.conf /etc/nginx/nginx.conf
