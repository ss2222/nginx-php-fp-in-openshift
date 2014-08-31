#!/bin/bash 

Current_DIR="$PWD"
echo ${Current_DIR}
source ${Current_DIR}/.openshift/action_hooks/common

PYTHON_VERSION="2.7.4"
PCRE_VERSION="8.35"
NGINX_VERSION="1.6.0"
MEMCACHED_VERSION="1.4.15"
ZLIB_VERSION="1.2.8"
PHP_VERSION="5.5.9"
PHP_VERSION="5.4.27"

APC_VERSION="3.1.13"
libyaml_package="yaml-0.1.4"

mkdir ${OPENSHIFT_HOMEDIR}/app-root/runtime/srv
if [ ! -d ${OPENSHIFT_HOMEDIR}/app-root/runtime/srv/nginx/sbin ]; then	
	cd $OPENSHIFT_TMP_DIR
	wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
	tar zxf nginx-${NGINX_VERSION}.tar.gz
	wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-${PCRE_VERSION}.tar.gz
	tar zxf pcre-${PCRE_VERSION}.tar.gz
	wget http://zlib.net/zlib-${ZLIB_VERSION}.tar.gz
	tar -zxf zlib-${ZLIB_VERSION}.tar.gz
	mkdir ${OPENSHIFT_HOMEDIR}/app-root/runtime/srv/nginx
	cd nginx-${NGINX_VERSION}	
	nohup sh -c "./configure\
	   --prefix={OPENSHIFT_HOMEDIR}/app-root/runtime/srv/nginx\
	   --with-pcre=$OPENSHIFT_TMP_DIR/pcre-${PCRE_VERSION}\
	   --with-zlib=$OPENSHIFT_TMP_DIR/zlib-${ZLIB_VERSION}\
		--with-http_ssl_module\
		--with-http_realip_module \
		--with-http_addition_module \
		--with-http_sub_module\
		--with-http_dav_module \
		--with-http_flv_module \
		--with-http_mp4_module \
		--with-http_gunzip_module\
		--with-http_gzip_static_module \
		--with-http_random_index_module \
		--with-http_secure_link_module\
		--with-http_stub_status_module \
		--with-mail \
		--with-mail_ssl_module \
		--with-file-aio\
		--with-ipv6	    " > $OPENSHIFT_LOG_DIR/Nginx_config.log 2>&1 & 
	tail -f $OPENSHIFT_DIY_LOG_DIR/Nginx_config.log
	
	nohup sh -c "make && make install && make clean"  > $OPENSHIFT_LOG_DIR/nginx_install.log 2>&1 &  
	tail -f $OPENSHIFT_LOG_DIR/nginx_install.log
	#./configure --with-pcre=$OPENSHIFT_TMP_DIR/pcre-8.35 --prefix=$OPENSHIFT_DATA_DIR/nginx --with-http_realip_module
	#make &&	make install
fi


echo "INSTALL PHP"
if [ ! -d ${OPENSHIFT_HOMEDIR}/app-root/runtime/srv/php-${PHP_VERSION}/sbin ]; then
	cd $OPENSHIFT_TMP_DIR
	wget http://us1.php.net/distributions/php-${PHP_VERSION}.tar.gz
	tar zxf php-${PHP_VERSION}.tar.gz
	cd php-${PHP_VERSION}
	wget -c http://us.php.net/get/php-${PHP_VERSION}.tar.gz/from/this/mirror
	tar -zxf mirror	
	mkdir ${OPENSHIFT_HOMEDIR}/app-root/runtime/srv/php-${PHP_VERSION}
	cd php-${PHP_VERSION}
	
	nohup sh -c "./configure --with-mysql=mysqlnd\
        --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd\
        --prefix=${OPENSHIFT_HOMEDIR}/app-root/runtime/srv/php-${PHP_VERSION}\
        --enable-fpm --with-zlib --enable-xml --enable-bcmath --with-curl --with-gd \
        --enable-zip --enable-mbstring --enable-sockets --enable-ftp"  > $OPENSHIFT_LOG_DIR/php_install_conf.log 2>&1 &  
	tail -f $OPENSHIFT_LOG_DIR/php_install_conf.log
	nohup sh -c "make && make install && make clean"  > $OPENSHIFT_LOG_DIR/php_install.log 2>&1 &  
	tail -f $OPENSHIFT_LOG_DIR/php_install.log
	#./configure --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --prefix=${OPENSHIFT_HOMEDIR}/app-root/runtime/srv/php-5.4.27 --enable-fpm --with-zlib --enable-xml --enable-bcmath --with-curl --with-gd --enable-zip --enable-mbstring --enable-sockets --enable-ftp
#	make && make install
	cp  $OPENSHIFT_TMP_DIR/php-${PHP_VERSION}/php.ini-production ${OPENSHIFT_HOMEDIR}/app-root/runtime/srv/php-${PHP_VERSION}/lib/php.ini
fi	
echo "Cleanup"

rm -rf $OPENSHIFT_TMP_DIR/*

nohup python ${DIR}/misc/ng_php_conf_hooks.py    > $OPENSHIFT_LOG_DIR/ng_php_conf_hooks.log 2>&1 &

#---starting nginx ----
nohup ${OPENSHIFT_HOMEDIR}/app-root/runtime/srv/nginx/sbin/nginx -c  ${OPENSHIFT_HOMEDIR}/app-root/repo/srv/nginx/conf/nginx.conf > $OPENSHIFT_LOG_DIR/nginx_run.log 2>&1 &  tail -f $OPENSHIFT_LOG_DIR/nginx_run.log
nohup ${OPENSHIFT_HOMEDIR}/app-root/runtime/srv/php-${PHP_VERSION}/sbin/php-fpm  > $OPENSHIFT_LOG_DIR/php_run.log 2>&1 & tail -f $OPENSHIFT_LOG_DIR/php_run.log

#---stoping nginx ----
nohup killall nginx > $OPENSHIFT_LOG_DIR/nginx_stop.log 2>&1 &
nohup killall php-fpm > $OPENSHIFT_LOG_DIR/php-fpm_stop.log 2>&1 &
