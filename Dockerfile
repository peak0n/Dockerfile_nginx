ARG ALPINE_VERSION=3.18
FROM alpine:${ALPINE_VERSION}

LABEL Description="Lightweight container with Nginx 1.24 & PHP 8.2 based on Alpine Linux."
# Setup document root
WORKDIR /var/www/html

# Install packages and remove default server definition
RUN apk add --no-cache \
  curl \
  nginx \
  php82 \
  php82-ctype \
  php82-curl \
  php82-dom \
  php82-fpm \
  php82-gd \
  php82-intl \
  php82-mbstring \
  php82-mysqli \
  php82-opcache \
  php82-openssl \
  php82-phar \
  php82-session \
  php82-xml \
  php82-xmlreader \
  supervisor

# Configure nginx - http
COPY config/nginx.conf /etc/nginx/nginx.conf
# Configure nginx - default server
COPY config/conf.d /etc/nginx/conf.d/

# Configure PHP-FPM
ENV PHP_INI_DIR /etc/php82
COPY config/fpm-pool.conf ${PHP_INI_DIR}/php-fpm.d/www.conf
COPY config/php.ini ${PHP_INI_DIR}/conf.d/custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R nobody.nobody /var/www/html /run /var/lib/nginx /var/log/nginx

# Create symlink for php
RUN ln -s /usr/bin/php82 /usr/bin/php

# Switch to use a non-root user from here on
USER nobody

# Add application
##COPY --chown=nobody html/ /var/www/html/

# Set the working directory
RUN mkdir /var/www/html/moodle
WORKDIR /var/www/html/moodle

# Download and install Moodle
RUN curl -L https://download.moodle.org/download.php/direct/stable402/moodle-latest-402.tgz | tar zxvf - --strip-components 1

# Create a Moodle data directory
RUN mkdir /var/www/html/moodledata
RUN chmod 0777 /var/www/html/moodledata

# Expose the port nginx is reachable on
EXPOSE 8080


# Create a directory for scripts outside of /tmp
USER root
RUN mkdir /scripts

# Copy the entrypoint script into the container
COPY entrypoint.sh /scripts/entrypoint.sh

# Make the script executable
RUN chmod +x /scripts/entrypoint.sh

# Set the entrypoint command
ENTRYPOINT ["/scripts/entrypoint.sh"]


# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping
