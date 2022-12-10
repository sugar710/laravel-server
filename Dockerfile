FROM php:8.1.9-fpm-alpine

# 更新系统源
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories

# 安装环境所需软件及GD & zip 库所需依赖
RUN apk add --no-cache vim nginx supervisor libjpeg-turbo-dev libpng-dev libwebp-dev freetype-dev libzip-dev

# 安装PHP组件
RUN docker-php-ext-install bcmath \
        && docker-php-source extract \
        && wget http://pecl.php.net/get/redis-5.3.7.tgz -O /tmp/redis.tgz \
        && tar -zxvf /tmp/redis.tgz -C /tmp \
        && mv /tmp/redis-*/ /usr/src/php/ext/redis \
        && docker-php-ext-install redis gd zip pdo_mysql \
        && docker-php-source delete \
        && rm /tmp/redis.tgz
COPY php.ini /usr/local/etc/php/conf.d/php.ini

# 配置composer
COPY composer.phar /usr/bin/composer
RUN composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/

# 配置Nginx
RUN sed -i '3s/nginx/www-data/' /etc/nginx/nginx.conf && chown www-data:www-data -R /var/lib/nginx
COPY default.conf /etc/nginx/http.d/

# 配置supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

COPY start-container /usr/local/bin/start-container

ENTRYPOINT ["start-container"]

# COPY --chown=www-data:www-data --chmod=0755 . /var/www/html

# RUN composer install --optimize-autoloader --no-dev
# RUN php artisan config:cache && php artisan route:cache && php artisan view:cache
