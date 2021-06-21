#!/bin/bash

if [ $# -ne 18 ]; then
    echo $0: usage: configure_magento.sh dbhost dbuser dbpassword dbname cname adminfirstname adminlastname adminemail adminuser adminpassword cachehost protocol magentolanguage magentocurrency magentotimezone magentoversion magentousername magentopassword
    exit 1
fi

# cname = public name of the service (magento.javieros.tk)

dbhost=$1
dbuser=$2
dbpassword=$3
dbname=$4
cname=${5,,}
adminfirst=$6
adminlast=$7
adminemail=$8
adminuser=$9
adminpassword=${10}
cachehost=${11}
protocol=${12}
magentolanguage=${13}
magentocurrency=${14}
magentotimezone=${15}
magentoversion=${16}
magentousername=${17}
magentopassword=${18}

cd

#Configure Magento credentials
php /usr/local/bin/composer config --global http-basic.repo.magento.com $magentousername $magentopassword

cd /var/www/html

php /usr/local/bin/composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition=$magentoversion .

find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} \;
find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} \;
chown -R :nginx .
chmod u+x bin/magento

cat << EOF > /var/www/html/pub/health
OK
EOF

if [ "$protocol" = "http" ]
then
  secure="--use-secure-admin=0 --use-secure=0"
else
  secure="--use-secure-admin=1 --use-secure=1 --base-url-secure=$protocol://$cname/"
fi

export PATH=$PATH:/var/www/html/bin

cd /var/www/html/bin
./magento module:disable {Magento_Elasticsearch,Magento_InventoryElasticsearch,Magento_Elasticsearch6,Magento_Elasticsearch7}

./magento setup:install --base-url=$protocol://$cname/ \
--db-host=$dbhost --db-name=$dbname --db-user=$dbuser --db-password=$dbpassword \
--admin-firstname=$adminfirst --admin-lastname=$adminlast --admin-email=$adminemail \
--admin-user=$adminuser --admin-password=$adminpassword --language=$magentolanguage \
--currency=$magentocurrency --timezone=$magentotimezone $secure

./magento module:disable {Magento_Elasticsearch,Magento_InventoryElasticsearch,Magento_Elasticsearch6,Magento_Elasticsearch7}

./magento config:set dev/static/sign 1

if [ "$protocol" = "http" ]
then

./magento config:set web/url/redirect_to_base 0

fi

magento setup:install --base-url=$protocol://$cname/ \
--db-host=$dbhost --db-name=$dbname --db-user=$dbuser --db-password=$dbpassword \
--admin-firstname=$adminfirst --admin-lastname=$adminlast --admin-email=$adminemail \
--admin-user=$adminuser --admin-password=$adminpassword --language=$magentolanguage \
--currency=$magentocurrency --timezone=$magentotimezone $secure

./magento info:adminuri > /home/ec2-user/adminuri
