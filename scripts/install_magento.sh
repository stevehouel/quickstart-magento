#!/bin/bash -e

# Set an initial value

function exportParams() {
    dbhost=`grep 'MySQLEndPointAddress' ${PARAMS_FILE} | awk -F'|' '{print $2}' | sed -e 's/^ *//g;s/ *$//g'`
    dbuser=`grep 'DBMasterUsername' ${PARAMS_FILE} | awk -F'|' '{print $2}' | sed -e 's/^ *//g;s/ *$//g'`
    dbpassword=`grep 'DBMasterUserPassword' ${PARAMS_FILE} | awk -F'|' '{print $2}' | sed -e 's/^ *//g;s/ *$//g'`
    dbname=`grep 'DBName' ${PARAMS_FILE} | awk -F'|' '{print $2}' | sed -e 's/^ *//g;s/ *$//g'`
    cname=`grep 'DNSName' ${PARAMS_FILE} | awk -F'|' '{print $2}' | sed -e 's/^ *//g;s/ *$//g'`
    adminfirst=`grep 'AdminFirstName' ${PARAMS_FILE} | awk -F'|' '{print $2}' | sed -e 's/^ *//g;s/ *$//g'`
    adminlast=`grep 'AdminLastName' ${PARAMS_FILE} | awk -F'|' '{print $2}' | sed -e 's/^ *//g;s/ *$//g'`
    adminemail=`grep 'AdminEmail' ${PARAMS_FILE} | awk -F'|' '{print $2}' | sed -e 's/^ *//g;s/ *$//g'`
    adminuser=`grep 'AdminUserName' ${PARAMS_FILE} | awk -F'|' '{print $2}' | sed -e 's/^ *//g;s/ *$//g'`
    adminpassword=`grep 'AdminPassword' ${PARAMS_FILE} | awk -F'|' '{print $2}' | sed -e 's/^ *//g;s/ *$//g'`
    cachehost=`grep 'ElastiCacheEndpoint' ${PARAMS_FILE} | awk -F'|' '{print $2}' | sed -e 's/^ *//g;s/ *$//g'`
    efsid=`grep 'FileSystem' ${PARAMS_FILE} | awk -F'|' '{print $2}' | sed -e 's/^ *//g;s/ *$//g'`
    magentourl=`grep 'MagentoReleaseMedia' ${PARAMS_FILE} | awk -F'|' '{print $2}' | sed -e 's/^ *//g;s/ *$//g'`
    magentoversion=`grep 'MagentoVersion' ${PARAMS_FILE} | awk -F'|' '{print $2}' | sed -e 's/^ *//g;s/ *$//g'`
    certificateid=`grep 'SSLCertificateId' ${PARAMS_FILE} | awk -F'|' '{print $2}' | sed -e 's/^ *//g;s/ *$//g'`
    magentolanguage=`grep 'MagentoLanguage' ${PARAMS_FILE} | awk -F'|' '{print $2}' | sed -e 's/^ *//g;s/ *$//g'`
    magentocurrency=`grep 'MagentoCurrency' ${PARAMS_FILE} | awk -F'|' '{print $2}' | sed -e 's/^ *//g;s/ *$//g'`
    magentotimezone=`grep 'MagentoTimezone' ${PARAMS_FILE} | awk -F'|' '{print $2}' | sed -e 's/^ *//g;s/ *$//g'`
    magentousername=`grep 'MagentoUsername' ${PARAMS_FILE} | awk -F'|' '{print $2}' | sed -e 's/^ *//g;s/ *$//g'`
    magentopassword=`grep 'MagentoPassword' ${PARAMS_FILE} | awk -F'|' '{print $2}' | sed -e 's/^ *//g;s/ *$//g'`
}

if [ $# -ne 1 ]; then
    echo $0: usage: install_magento.sh "<param-file-path>"
    exit 1
fi

PARAMS_FILE=$1

dbhost='NONE'
dbuser='NONE'
dbpassword='NONE'
dbname='NONE'
cname='NONE'
adminfirst='NONE'
adminlast='NONE'
adminemail='NONE'
adminuser='NONE'
adminpassword='NONE'
cachehost='NONE'
efsid='NONE'
magentourl='NONE'
magentoversion='NONE'
certificateid='NONE'
magentolanguage='NONE'
magentocurrency='NONE'
magentotimezone='NONE'
magentousername='NONE'
magentopassword='NONE'

#install_magento.sh dbhost dbuser dbpassword dbname cname adminfirstname adminlastname adminemail adminuser adminpassword cachehost efsid magentourl magentoversion certificateid magentolanguage magentocurrency magentotimezone

if [ -f ${PARAMS_FILE} ]; then
    echo "Extracting parameter values from params file"
    exportParams
else
    echo "Parameters file not found or inaccessible."
    exit 1
fi

# cname = public name of the service (magento.javieros.tk)


EC2_AVAIL_ZONE=`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone`
EC2_REGION="`echo \"$EC2_AVAIL_ZONE\" | sed -e 's:\([0-9][0-9]*\)[a-z]*\$:\\1:'`"

amazon-linux-extras install -y nginx1
amazon-linux-extras install -y php7.4

yum -y update
yum install -y libsodium php php-cli php-pear php-devel php-common php-mysqlnd php-pdo php-opcache php-xml php-mcrypt php-gd php-soap php-redis php-bcmath php-intl php-sodium php-mbstring php-json php-iconv php-fpm php-zip mysql

service nginx restart
service php-fpm restart

yum install wget unzip

export HOME=/root
export COMPOSER_HOME="/root/.config/composer";
export PATH=$PATH:/usr/local/bin

php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('sha384', 'composer-setup.php') === '756890a4488ce9024fc62c56153228907f1545c228516cbf63f885e036d37e9a59d27d63f46af1d4d07ee0f76181c7d3') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php composer-setup.php
mv composer.phar /usr/local/bin/composer

/etc/ssl/certs/make-dummy-cert /etc/ssl/certs/magento


cat << EOF > /etc/php-fpm.conf
[global]
pid = /var/run/php-fpm/php-fpm.pid
error_log = /var/log/php-fpm/error.log
daemonize = yes
[www]
user = nginx
group = nginx
listen = /var/run/php-fpm/php-fpm.sock
listen.owner = nginx
listen.group = nginx
pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35
slowlog = /var/log/php-fpm/www-slow.log
php_admin_value[error_log] = /var/log/php-fpm/www-error.log
php_admin_flag[log_errors] = on
php_value[session.save_handler] = files
php_value[session.save_path]    = /var/lib/php/session
php_value[soap.wsdl_cache_dir]  = /var/lib/php/wsdlcache
EOF

service php-fpm restart

cat << 'EOF' > /etc/nginx/nginx.conf
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /var/run/nginx.pid;
events {
    worker_connections 1024;
}

http {
    upstream fastcgi_backend {
        server   unix:/var/run/php-fpm/php-fpm.sock;
    }
    server {
        listen 80;
        server_name magento-sample;
        set $MAGE_ROOT /var/www/html;
        set $MAGE_DEBUG_SHOW_ARGS 0;

        root $MAGE_ROOT/pub;

        index index.php;
        autoindex off;
        charset UTF-8;
        error_page 404 403 = /errors/404.php;
        #add_header "X-UA-Compatible" "IE=Edge";


        # Deny access to sensitive files
        location /.user.ini {
            deny all;
        }

        # PHP entry point for setup application
        location ~* ^/setup($|/) {
            root $MAGE_ROOT;
            location ~ ^/setup/index.php {
                fastcgi_pass   fastcgi_backend;

                fastcgi_param  PHP_FLAG  "session.auto_start=off \n suhosin.session.cryptua=off";
                fastcgi_param  PHP_VALUE "memory_limit=756M \n max_execution_time=600";
                fastcgi_read_timeout 600s;
                fastcgi_connect_timeout 600s;

                fastcgi_index  index.php;
                fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
                include        fastcgi_params;
            }

            location ~ ^/setup/(?!pub/). {
                deny all;
            }

            location ~ ^/setup/pub/ {
                add_header X-Frame-Options "SAMEORIGIN";
            }
        }

        # PHP entry point for update application
        location ~* ^/update($|/) {
            root $MAGE_ROOT;

            location ~ ^/update/index.php {
                fastcgi_split_path_info ^(/update/index.php)(/.+)$;
                fastcgi_pass   fastcgi_backend;
                fastcgi_index  index.php;
                fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
                fastcgi_param  PATH_INFO        $fastcgi_path_info;
                include        fastcgi_params;
            }

            # Deny everything but index.php
            location ~ ^/update/(?!pub/). {
                deny all;
            }

            location ~ ^/update/pub/ {
                add_header X-Frame-Options "SAMEORIGIN";
            }
        }

        location / {
            try_files $uri $uri/ /index.php$is_args$args;
        }

        location /pub/ {
            location ~ ^/pub/media/(downloadable|customer|import|custom_options|theme_customization/.*\.xml) {
                deny all;
            }
            alias $MAGE_ROOT/pub/;
            add_header X-Frame-Options "SAMEORIGIN";
        }

        location /static/ {
            # Uncomment the following line in production mode
            expires max;

            # Remove signature of the static files that is used to overcome the browser cache
            location ~ ^/static/version {
                rewrite ^/static/(version\d*/)?(.*)$ /static/$2 last;
            }

            location ~* \.(ico|jpg|jpeg|png|gif|svg|js|css|swf|eot|ttf|otf|woff|woff2|html|json)$ {
                add_header Cache-Control "public";
                add_header X-Frame-Options "SAMEORIGIN";
                expires +1y;

                if (!-f $request_filename) {
                    rewrite ^/static/(version\d*/)?(.*)$ /static.php?resource=$2 last;
                }
            }
            location ~* \.(zip|gz|gzip|bz2|csv|xml)$ {
                add_header Cache-Control "no-store";
                add_header X-Frame-Options "SAMEORIGIN";
                expires    off;

                if (!-f $request_filename) {
                rewrite ^/static/(version\d*/)?(.*)$ /static.php?resource=$2 last;
                }
            }
            if (!-f $request_filename) {
                rewrite ^/static/(version\d*/)?(.*)$ /static.php?resource=$2 last;
            }
            add_header X-Frame-Options "SAMEORIGIN";
        }

        location /media/ {
            try_files $uri $uri/ /get.php$is_args$args;

            location ~ ^/media/theme_customization/.*\.xml {
                deny all;
            }

            location ~* \.(ico|jpg|jpeg|png|gif|svg|js|css|swf|eot|ttf|otf|woff|woff2)$ {
                add_header Cache-Control "public";
                add_header X-Frame-Options "SAMEORIGIN";
                expires +1y;
                try_files $uri $uri/ /get.php$is_args$args;
            }
            location ~* \.(zip|gz|gzip|bz2|csv|xml)$ {
                add_header Cache-Control "no-store";
                add_header X-Frame-Options "SAMEORIGIN";
                expires    off;
                try_files $uri $uri/ /get.php$is_args$args;
            }
            add_header X-Frame-Options "SAMEORIGIN";
        }

        location /media/customer/ {
            deny all;
        }

        location /media/downloadable/ {
            deny all;
        }

        location /media/import/ {
            deny all;
        }

        location /media/custom_options/ {
            deny all;
        }

        location /errors/ {
            location ~* \.xml$ {
                deny all;
            }
        }

        # PHP entry point for main application
        location ~ ^/(index|get|static|errors/report|errors/404|errors/503|health_check)\.php$ {
            try_files $uri =404;
            fastcgi_pass   fastcgi_backend;
            fastcgi_buffers 16 16k;
            fastcgi_buffer_size 32k;

            fastcgi_param  PHP_FLAG  "session.auto_start=off \n suhosin.session.cryptua=off";
            fastcgi_param  PHP_VALUE "memory_limit=756M \n max_execution_time=18000";
            fastcgi_read_timeout 600s;
            fastcgi_connect_timeout 600s;

            fastcgi_index  index.php;
            fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
            include        fastcgi_params;
        }

        gzip on;
        gzip_disable "msie6";

        gzip_comp_level 6;
        gzip_min_length 1100;
        gzip_buffers 16 8k;
        gzip_proxied any;
        gzip_types
            text/plain
            text/css
            text/js
            text/xml
            text/javascript
            application/javascript
            application/x-javascript
            application/json
            application/xml
            application/xml+rss
            image/svg+xml;
        gzip_vary on;

        # Banned locations (only reached if the earlier PHP entry point regexes don't match)
        location ~* (\.php$|\.phtml$|\.htaccess$|\.git) {
            deny all;
        }
    }
}
EOF

cat << 'EOF' > /etc/php.ini
[PHP]
engine = On
short_open_tag = Off
precision = 14
output_buffering = 4096
zlib.output_compression = Off
implicit_flush = Off
unserialize_callback_func =
serialize_precision = 17
disable_functions =
disable_classes =
zend.enable_gc = On
expose_php = On
max_execution_time = 600
max_input_time = 60
memory_limit = 768M
error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT
display_errors = Off
display_startup_errors = Off
log_errors = On
log_errors_max_len = 1024
ignore_repeated_errors = Off
ignore_repeated_source = Off
report_memleaks = On
track_errors = Off
html_errors = On
variables_order = "GPCS"
request_order = "GP"
register_argc_argv = Off
auto_globals_jit = On
post_max_size = 8M
auto_prepend_file =
auto_append_file =
default_mimetype = "text/html"
default_charset = "UTF-8"
doc_root =
user_dir =
enable_dl = Off
file_uploads = On
upload_max_filesize = 2M
max_file_uploads = 20
allow_url_fopen = On
allow_url_include = Off
default_socket_timeout = 60
[CLI Server]
cli_server.color = On
[Date]
[filter]
[iconv]
[intl]
[sqlite]
[sqlite3]
[Pcre]
pcre.jit=0
[Pdo]
[Pdo_mysql]
pdo_mysql.cache_size = 2000
pdo_mysql.default_socket=
[Phar]
[mail function]
sendmail_path = /usr/sbin/sendmail -t -i
mail.add_x_header = On
[SQL]
sql.safe_mode = Off
[ODBC]
odbc.allow_persistent = On
odbc.check_persistent = On
odbc.max_persistent = -1
odbc.max_links = -1
odbc.defaultlrl = 4096
odbc.defaultbinmode = 1
[Interbase]
ibase.allow_persistent = 1
ibase.max_persistent = -1
ibase.max_links = -1
ibase.timestampformat = "%Y-%m-%d %H:%M:%S"
ibase.dateformat = "%Y-%m-%d"
ibase.timeformat = "%H:%M:%S"
[MySQLi]
mysqli.max_persistent = -1
mysqli.allow_persistent = On
mysqli.max_links = -1
mysqli.cache_size = 2000
mysqli.default_port = 3306
mysqli.default_socket =
mysqli.default_host =
mysqli.default_user =
mysqli.default_pw =
mysqli.reconnect = Off
[mysqlnd]
mysqlnd.collect_statistics = On
mysqlnd.collect_memory_statistics = Off
[PostgreSQL]
pgsql.allow_persistent = On
pgsql.auto_reset_persistent = Off
pgsql.max_persistent = -1
pgsql.max_links = -1
pgsql.ignore_notice = 0
pgsql.log_notice = 0
[bcmath]
bcmath.scale = 0
[browscap]
[Session]
session.save_handler = files
session.use_strict_mode = 0
session.use_cookies = 1
session.use_only_cookies = 1
session.name = PHPSESSID
session.auto_start = 0
session.cookie_lifetime = 0
session.cookie_path = /
session.cookie_domain =
session.cookie_httponly =
session.serialize_handler = php
session.gc_probability = 1
session.gc_divisor = 1000
session.gc_maxlifetime = 1440
session.referer_check =
session.cache_limiter = nocache
session.cache_expire = 180
session.use_trans_sid = 0
session.hash_function = 0
session.hash_bits_per_character = 5
url_rewriter.tags = "a=href,area=href,frame=src,input=src,form=fakeentry"
[Assertion]
zend.assertions = -1
[mbstring]
[gd]
[exif]
[Tidy]
tidy.clean_output = Off
[soap]
soap.wsdl_cache_enabled=1
soap.wsdl_cache_dir="/tmp"
soap.wsdl_cache_ttl=86400
soap.wsdl_cache_limit = 5
[sysvshm]
[ldap]
ldap.max_links = -1
[mcrypt]
[dba]
[curl]
[openssl]
EOF

mkdir -p /var/www/html
chown ec2-user:nginx /var/www/html
chmod g+w /var/www/html/
usermod -g nginx ec2-user
chgrp -R nginx /var/lib/php/*
service nginx start

chmod a+x configure_magento.sh
mv configure_magento.sh /tmp

protocol="https"
if [ -z "$certificateid" ]
then
        protocol="http"
fi

sudo -u ec2-user /tmp/configure_magento.sh $dbhost $dbuser $dbpassword $dbname $cname $adminfirst $adminlast $adminemail $adminuser $adminpassword $cachehost $protocol $magentolanguage $magentocurrency $magentotimezone $magentoversion $magentousername $magentopassword

mount -t nfs4 -o vers=4.1 $efsid.efs.$EC2_REGION.amazonaws.com:/ /var/www/html/pub/media

# Remove passwords from files
sed -i s/${dbpassword}/xxxxx/g /var/log/cloud-init.log
sed -i s/${adminpassword}/xxxxx/g /var/log/cloud-init.log

# Remove params file used in bootstrapping
rm -f ${PARAMS_FILE}

cat << EOF > magento.cron
* * * * * /usr/bin/php -c /etc/php.ini /var/www/html/bin/magento cron:run | grep -v "Ran jobs by schedule" >> /var/www/html/var/log/magento.cron.log
* * * * * /usr/bin/php -c /etc/php.ini /var/www/html/update/cron.php >> /var/www/html/var/log/update.cron.log
* * * * * /usr/bin/php -c /etc/php.ini /var/www/html/bin/magento setup:cron:run >> /var/www/html/var/log/setup.cron.log
EOF

crontab -u ec2-user magento.cron