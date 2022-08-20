FROM php:8.1.9-fpm-alpine

# 更新系统源
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories

# 安装GD & zip 库所需依赖
RUN apk add --no-cache libjpeg-turbo-dev libpng-dev libwebp-dev freetype-dev libzip-dev

# 安装PHP组件
RUN docker-php-ext-install gd zip pdo_mysql
COPY php.ini /usr/local/etc/php/conf.d/php.ini

# 配置composer
COPY composer.phar /usr/bin/composer
RUN composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/

# 安装并配置Nginx
RUN apk add nginx && sed -i '3s/nginx/www-data/' /etc/nginx/nginx.conf
RUN chown www-data:www-data -R /var/lib/nginx
COPY default.conf /etc/nginx/http.d/

# 安装并配置supervisor
RUN apk add supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY start-container /usr/local/bin/start-container

ENTRYPOINT ["start-container"]

# COPY --chown=www-data:www-data . /var/www/html

# RUN composer install --optimize-autoloader --no-dev
# RUN php artisan config:cache && php artisan route:cache && php artisan view:cache
