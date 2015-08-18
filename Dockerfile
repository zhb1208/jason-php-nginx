FROM centos:centos7.1.1503
MAINTAINER Powered by jason<zhb1208@gmail.com> 

ADD /conf/nginx.repo /etc/yum.repos.d/nginx.repo
RUN rpm -Uvh http://mirror.webtatic.com/yum/el6/latest.rpm

RUN yum -y update && \
	yum clean all
RUN yum -y install epel-release && \
	yum clean all
RUN yum -y install nginx && \
	yum clean all

# 	httpd \
RUN yum install -y \
    httpd \
	php-gd \
	php-cli \
	php-fpm \
	php-mysql \
	php-pgsql \
	php-sqlite \
	php-curl \
	php-mcrypt \
	php-memcache \
	php-intl \
	php-imap \
	php-redis \
	php-tidy \
	php-xml \
	pwgen \
	supervisor \
	bash-completion \
	openssh-server \
	openssh-clients \
	psmisc tar

# 
# Install OCI8: http://km.com/PHP_Extensions_DB#OCI8_.2BIBQ_Oracle_OCI8
# 
# Refer to 
# 	http://shiki.me/blog/installing-pdo_oci-and-oci8-php-extensions-on-centos-6-4-64bit/
# 	http://ccm.net/faq/4987-linux-redhat-oracle-installing-pdo-oci-and-oci8-modules
# 	http://antoine.hordez.fr/2012/09/30/howto-install-oracle-oci8-on-rhel-centos-fedora/
## http://pecl.php.net/package/oci8
RUN yum -y install php-pear php-devel
RUN yum -y install zlib zlib-devel
RUN yum -y install bc libaio glibc
RUN yum -y install gcc make lrzsz
RUN yum clean all
ADD ./oracle-instantclient12.1-basic-12.1.0.2.0-1.x86_64.rpm /oracle-instantclient12.1-basic-12.1.0.2.0-1.x86_64.rpm
RUN rpm -hiv /oracle-instantclient12.1-basic-12.1.0.2.0-1.x86_64.rpm
## Additional header files and an example makefile for developing Oracle applications with Instant Client
ADD ./oracle-instantclient12.1-devel-12.1.0.2.0-1.x86_64.rpm /oracle-instantclient12.1-devel-12.1.0.2.0-1.x86_64.rpm
RUN rpm -hiv /oracle-instantclient12.1-devel-12.1.0.2.0-1.x86_64.rpm
COPY ./oci8-2.0.8.tar /oci8-2.0.8.tar
RUN tar xvf /oci8-2.0.8.tar
RUN cd /oci8-2.0.8; phpize; ./configure --with-oci8=shared,instantclient,/usr/lib/oracle/12.1/client64/lib/
RUN cd /oci8-2.0.8; make; make install; make clean
RUN echo extension=oci8.so > /etc/php.d/oci8.ini

# install imagick
RUN yum install -y ImageMagick  ImageMagick-devel ImageMagick-perl
RUN pecl install imagick
RUN echo extension=imagick.so > /etc/php.d/imagick.ini

#RUN setsebool -P httpd_execmem 1
#ADD ./foreground.sh /etc/apache2/foreground.sh
ADD ./supervisord.conf /etc/supervisord.conf

## httpd
RUN echo %sudo	ALL=NOPASSWD: ALL >> /etc/sudoers
#RUN chown -R apache:apache /var/www/
#RUN chmod 755 /etc/apache2/foreground.sh

## nginx config
RUN groupadd www
RUN useradd -g www www
RUN chown -R www:www /var/www/
RUN mkdir /etc/nginx/logs
RUN mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
RUN mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.bak
RUN mv /etc/nginx/conf.d/example_ssl.conf /etc/nginx/conf.d/example_ssl.conf.bak
ADD ./conf/nginx.conf /etc/nginx/nginx.conf
ADD ./conf/fcgi.conf /etc/nginx/fcgi.conf
ADD ./conf/conf.d/default.conf /etc/nginx/conf.d/default.conf
ADD ./conf/conf.d/fladminsso.feiliu.com.conf /etc/nginx/conf.d/fladminsso.feiliu.com.conf
ADD ./conf/conf.d/test.localhost.conf /etc/nginx/conf.d/test.localhost.conf

RUN mkdir /var/run/sshd
# Create User for SSH
# __create_user() {
# # Create a user to SSH into as.
# SSH_USERPASS=`pwgen -c -n -1 8`
# useradd -G wheel user
# echo user:$SSH_USERPASS | chpasswd
# echo ssh user password: $SSH_USERPASS
# }
# https://docs.docker.com/examples/running_ssh_service/
RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N '' 
RUN useradd -G wheel user; echo 'user:docker' | chpasswd; echo 'root:hellonihao' | chpasswd
RUN sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/g' /etc/ssh/sshd_config

EXPOSE 80
EXPOSE 22

#CMD ["/bin/bash", "/start.sh"]
ENTRYPOINT ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]

## docker build -t twotwo/php .
## debug: docker run -ti -v ~/docker_site:/var/www/html twotwo/php
## docker run -d -p 8000:80 -p 2222:22 --name php -v ~/docker/site:/var/www/html twotwo/php:0.1
## echo "$(docker logs php | grep password)"
## sshpass -phellonihao ssh -p 2222 root@192.168.59.103