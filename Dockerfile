# 构建 swoole、redis
FROM php:8.1.20-fpm-alpine as builder

RUN apk add --no-cache --virtual .build-deps autoconf gcc g++ make libffi-dev openssl-dev libtool pcre-dev zlib-dev

RUN apk add --no-cache libjpeg-turbo-dev libpng-dev libwebp-dev freetype-dev libzip-dev

RUN pecl install swoole redis && docker-php-ext-install gd zip pdo_mysql bcmath


# 运行环境
FROM php:8.1.20-fpm-alpine

MAINTAINER 冯毅 <hxtgirq710@gmail.com>

# 更新系统源
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories

# 定义扩展路径
ARG EXT_PATH=/usr/local/lib/php/extensions/no-debug-non-zts-20210902

# 安装环境所需软件 及GD & zip 库所需依赖
RUN apk add --no-cache vim nginx supervisor libjpeg-turbo-dev libpng-dev libwebp-dev freetype-dev libzip-dev

# 配置 composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/

# 复制各扩展库
COPY --from=builder ${EXT_PATH}/swoole.so ${EXT_PATH}/redis.so ${EXT_PATH}/gd.so ${EXT_PATH}/zip.so ${EXT_PATH}/pdo_mysql.so ${EXT_PATH}/bcmath.so ${EXT_PATH}/

# 启用PHP扩展
RUN docker-php-ext-enable swoole redis gd zip pdo_mysql bcmath opcache && rm -rf /var/cache/apk/* && rm -rf /tmp/*

# 复制PHP配置
COPY php.ini /usr/local/etc/php/conf.d/php.ini

# 配置Nginx
RUN sed -i '3s/nginx/www-data/' /etc/nginx/nginx.conf && chown www-data:www-data -R /var/lib/nginx
COPY default.conf /etc/nginx/http.d/

# 配置supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# 复制入口文件
COPY start-container /usr/local/bin/start-container

ENTRYPOINT ["start-container"]

# COPY --chown=www-data:www-data --chmod=0755 . /var/www/html

# RUN composer install --optimize-autoloader --no-dev
# RUN php artisan config:cache && php artisan route:cache && php artisan view:cache
