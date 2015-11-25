FROM ubuntu:trusty
MAINTAINER Fernando Mayo <fernando@tutum.co>

# Install base packages
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -yq install \
        curl \
        autoconf \
        apache2 \
        libapache2-mod-php5 \
        php5-mysql \
        php5-mcrypt \
        php5-gd \
        php5-curl \
        php-pear \
        php5-dev \
        php-apc && \
    rm -rf /var/lib/apt/lists/* && \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN /usr/sbin/php5enmod mcrypt
ENV ALLOW_OVERRIDE **False**

#replace and modify apache2.conf and php.ini
ADD bulid/apache2.conf /etc/apache2/apache2.conf
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf && \
    sed -i "s/variables_order.*/variables_order = \"EGPCS\"/g" /etc/php5/apache2/php.ini

#memcache
RUN pecl channel-update pecl.php.net
RUN pecl install memcache
RUN echo "extension=memcache.so" >> /etc/php5/apache2/php.ini

#memcached
RUN apt-get update
RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y --force-yes memcached php5-memcached
RUN echo "extension=memcached.so" >> /etc/php5/apache2/php.ini

#open rewrite module
RUN a2enmod rewrite
RUN sed -i "s/AllowOverride None/AllowOverride All/g" /etc/apache2/apache2.conf

#php upload file setting
RUN sed -i "s+;upload_tmp_dir =+upload_tmp_dir = /app/Runtime+g" /etc/php5/apache2/php.ini && \
    sed -i "s+;open_basedir =+open_basedir = /app/Runtime+g" /etc/php5/apache2/php.ini && \
    sed -i "s+post_max_size = 8M+post_max_size = 16M+g" /etc/php5/apache2/php.ini && \
    sed -i "s+upload_max_filesize = 2M+upload_max_filesize = 6M+g" /etc/php5/apache2/php.ini

#open mpm_prefork module
RUN a2enmod mpm_prefork
ADD bulid/mpm_prefork.conf /etc/apache2/mods-available/mpm_prefork.conf

#replace security.conf
ADD bulid/security.conf /etc/apache2/conf-available/security.conf

# Add image configuration and scripts
ADD run.sh /run.sh
RUN chmod 755 /*.sh

# Configure /app folder with sample app
RUN mkdir -p /app && rm -fr /var/www/html && ln -s /app /var/www/html

EXPOSE 80
WORKDIR /app
CMD ["/run.sh"]
