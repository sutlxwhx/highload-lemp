#!/usr/bin/env bash
#
# Follow up commands are best suitable for clean Ubuntu 16.04 installation
# All commands are executed by the root user
# Nginx library is installed from custom ppa/ repository
# https://launchpad.net/~hda-me/+archive/ubuntu/nginx-stable
# This will not be available for any other OS rather then Ubuntu
#
# Disable user promt
DEBIAN_FRONTEND=noninteractive
# Update list of available packages
apt-get update -y -q
# Update installed packages
apt-get DPkg::options::="--force-confdef" -o DPkg::options::="--force-confold" dist-upgrade -y -q
# Install the most common packages that will be usefull under development environment
apt-get install zip unzip fail2ban htop sqlite3 nload mlocate nano memcached python-software-properties software-properties-common -y -q
# Install Nginx && PHP-FPM stack
apt-get install php7.0-curl php7.0-fpm php7.0-gd php7.0-mbstring php7.0-mcrypt php7.0-opcache php7.0-xml php7.0-sqlite php7.0-mysql php-imagick -y -q
# Create a folder to backup current installation of Nginx && PHP-FPM
now=$(date +"%Y-%m-%d_%H-%M-%S") 
mkdir /backup/
mkdir /backup/$now/nginx/ && mkdir /backup/$now/php/
# Create a full backup of previous Nginx configuration
cp -r /etc/nginx/ /backup/$now/nginx/ 
# Create a full backup of previous PHP configuration
cp -r /etc/php/ /backup/$now/php/
# Delete previous Nginx installation
apt-get purge nginx-core nginx-common nginx -y -q
apt-get autoremove -y -q
# Add custom repository for Nginx
apt-add-repository ppa:hda-me/nginx-stable -y
# Update list of available packages
apt-get update -y -q
# Install custom Nginx package
apt-get install nginx -y -q
systemctl unmask nginx.service
# Install Brottli package for Nginx
# https://blog.cloudflare.com/results-experimenting-brotli/
apt-get install nginx-module-brotli -y -q
# Disable extrenal access to PHP-FPM scripts
sed -i "s/^;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.0/fpm/php.ini
# Create an additional configurational folder for Nginx
mkdir /etc/nginx/conf.d
# Download list of bad bots, bad ip's and bad referres
# https://github.com/mitchellkrogza/nginx-badbot-blocker
wget -O /etc/nginx/conf.d/blacklist.conf https://raw.githubusercontent.com/mariusv/nginx-badbot-blocker/master/blacklist.conf
wget -O /etc/nginx/conf.d/blockips.conf https://raw.githubusercontent.com/mariusv/nginx-badbot-blocker/master/blockips.conf
# Create default file for Nginx for where to find new websites that are pointed to this IP
echo -e 'server {\n\tlisten 80;\n\tserver_name $host;\n\troot /var/www/$host;\n\tindex index.php index.html;\n\n\tlocation ~ \.php$ {\n\t\tinclude fastcgi-php.conf;\n\t\tinclude fastcgi_params;\n\t\tfastcgi_pass unix:/run/php/php7.0-fpm.sock;\n\t}\n\n\tlocation / {\n\t\tif ($bad_bot = 1) {return 503;}\n\t\tif ($bad_referer) {return 503;}\n\t\tif ($bad_urls1) {return 503;}\n\t\tif ($bad_urls2) {return 503;}\n\t\tif ($bad_urls3) {return 503;}\n\t\tif ($bad_urls4) {return 503;}\n\t\tif ($bad_urls5) {return 503;}\n\t\tif ($bad_urls6) {return 503;}\n\t\ttry_files $uri $uri/ /index.php?$args;\n\t}\n\n\tlocation ~ ^/(status|ping)$ {\n\t\tinclude fastcgi_params;\n\t\tfastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;\n\t\tfastcgi_pass unix:/run/php/php7.0-fpm.sock;\n\t}\n}' > /etc/nginx/sites-enabled/default
# Create fastcgi.conf
echo -e 'fastcgi_param  SCRIPT_FILENAME    $document_root$fastcgi_script_name;\nfastcgi_param  QUERY_STRING       $query_string;\nfastcgi_param  REQUEST_METHOD     $request_method;\nfastcgi_param  CONTENT_TYPE       $content_type;\nfastcgi_param  CONTENT_LENGTH     $content_length;\n\nfastcgi_param  SCRIPT_NAME        $fastcgi_script_name;\nfastcgi_param  REQUEST_URI        $request_uri;\nfastcgi_param  DOCUMENT_URI       $document_uri;\nfastcgi_param  DOCUMENT_ROOT      $document_root;\nfastcgi_param  SERVER_PROTOCOL    $server_protocol;\nfastcgi_param  HTTPS              $https if_not_empty;\n\nfastcgi_param  GATEWAY_INTERFACE  CGI/1.1;\nfastcgi_param  SERVER_SOFTWARE    nginx/$nginx_version;\n\nfastcgi_param  REMOTE_ADDR        $remote_addr;\nfastcgi_param  REMOTE_PORT        $remote_port;\nfastcgi_param  SERVER_ADDR        $server_addr;\nfastcgi_param  SERVER_PORT        $server_port;\nfastcgi_param  SERVER_NAME        $server_name;\n\n# PHP only, required if PHP was built with --enable-force-cgi-redirect\nfastcgi_param  REDIRECT_STATUS    200;' > /etc/nginx/fastcgi.conf
# Create fastcgi-php.conf
echo -e '# regex to split $uri to $fastcgi_script_name and $fastcgi_path\nfastcgi_split_path_info ^(.+\.php)(/.+)$;\n\n# Check that the PHP script exists before passing it\ntry_files $fastcgi_script_name =404;\n\n# Bypass the fact that try_files resets $fastcgi_path_info\n# see: http://trac.nginx.org/nginx/ticket/321\nset $path_info $fastcgi_path_info;\nfastcgi_param PATH_INFO $path_info;\n\nfastcgi_index index.php;\ninclude fastcgi.conf;' > /etc/nginx/fastcgi-php.conf
# Create nginx.conf
wget -O /etc/nginx/nginx.conf https://raw.githubusercontent.com/sutlxwhx/Highload-LEMP-Installation/master/nginx.conf
# Tweak memcached configuration
# Disable memcached vulnerability https://thehackernews.com/2018/03/memcached-ddos-exploit-code.html
sed -i "s/^-p 11211/#-p 11211/" /etc/memcached.conf
sed -i "s/^-l 127.0.0.1/#-l 127.0.0.1/" /etc/memcached.conf
# Increase memcached perfomance by using sockets https://guides.wp-bullet.com/configure-memcached-to-use-unix-socket-speed-boost/
echo -e "-s /tmp/memcached.sock" >> /etc/memcached.conf
echo -e "-a 775" >> /etc/memcached.conf
# Restart memcached service
service memcached restart
# Add repository for MariaDB 10.2
apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://ams2.mirrors.digitalocean.com/mariadb/repo/10.2/ubuntu xenial main' -y
# Update list of available packages
apt-get update -y -q
# Use md5 hash of your hostname to define a root password for MariDB
password=$(hostname | md5sum | awk '{print $1}')
debconf-set-selections <<< "mariadb-server-10.2 mysql-server/root_password password $password"
debconf-set-selections <<< "mariadb-server-10.2 mysql-server/root_password_again password $password"
# Install MariaDB package
apt-get install mariadb-server -y -q
# Add custom configuration for your Mysql
# All modified variables are available at https://mariadb.com/kb/en/library/server-system-variables/
echo -e "\n[mysqld]\nmax_connections=24\nconnect_timeout=10\nwait_timeout=10\nthread_cache_size=24\nsort_buffer_size=1M\njoin_buffer_size=1M\ntmp_table_size=8M\nmax_heap_table_size=1M\nbinlog_cache_size=8M\nbinlog_stmt_cache_size=8M\nkey_buffer_size=1M\ntable_open_cache=64\nread_buffer_size=1M\nquery_cache_limit=1M\nquery_cache_size=8M\nquery_cache_type=1\ninnodb_buffer_pool_size=8M\ninnodb_open_files=1024\ninnodb_io_capacity=1024\ninnodb_buffer_pool_instances=1" >> /etc/mysql/my.cnf
# Write down current password for MariaDB in my.cnf
echo -e "\n[client]\nuser = root\npassword = $password" >> /etc/mysql/my.cnf
# Restart MariaDB
service mysql restart
# Install Mysqltuner for future improvements of MariaDB installation
apt-get install mysqltuner -y -q
# Create default folder for future websites
mkdir /var/www
# Create Hello World page
mkdir /var/www/test.com
echo -e "<html>\n<body>\n<h1>Hello World!<h1>\n</body>\n</html>" > /var/www/test.com/index.html
# Create opcache page
wget -O /var/www/test.com/opcache.php https://github.com/rlerdorf/opcache-status/blob/master/opcache.php
# Create phpinfo page
echo -e "<?php phpinfo();" > /var/www/test.com/info.php
# Give Nginx permissions to be able to access these websites
chown -R www-data:www-data /var/www/*
# Maximize the limits of file system usage
echo -e "*       soft    nofile  1000000" >> /etc/security/limits.conf
echo -e "*       hard    nofile  1000000" >> /etc/security/limits.conf
# Switch to the ondemand state of PHP-FPM
sed -i "s/^pm = .*/pm = ondemand/" /etc/php/7.0/fpm/pool.d/www.conf
# Use such number of children that will not hurt other parts of the system
# Let's assume that system itself needs 128 MB of RAM
# Let's assume that we let have MariaDB another 256 MB to run
# And finally let's assume that Nginx will need something like 8 MB to run
# On the 1 GB system that leads up to 632 MB of free memory
# If we give one PHP-FPM child a moderate amount of RAM for example 32 MB that will let us create 19 PHP-FPM proccesses at max
# Check median of how much PHP-FPM child consumes with the following command
# ps --no-headers -o "rss,cmd" -C php-fpm7.0 | awk '{ sum+=$1 } END { printf ("%d%s\n", sum/NR/1024,"M") }'
ram=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
free=$(((ram/1024)-128-256-8))
php=$(((free/32)))
children=$(printf %.0f $php)
sed -i "s/^pm.max_children = .*/pm.max_children = $children/" /etc/php/7.0/fpm/pool.d/www.conf
# Comment default dynamic mode settings and make them more adequate
sed -i "s/^pm.start_servers = .*/;pm.start_servers = 5/" /etc/php/7.0/fpm/pool.d/www.conf
sed -i "s/^pm.min_spare_servers = .*/;pm.min_spare_servers = 2/" /etc/php/7.0/fpm/pool.d/www.conf
sed -i "s/^pm.max_spare_servers = .*/;pm.max_spare_servers = 2/" /etc/php/7.0/fpm/pool.d/www.conf
# State what amount of request one PHP-FPM child can sustain
sed -i "s/^;pm.max_requests = .*/pm.max_requests = 400/" /etc/php/7.0/fpm/pool.d/www.conf
# State after what amount of time unused PHP-FPM children will stop
sed -i "s/^;pm.process_idle_timeout = .*/pm.process_idle_timeout = 10s;/" /etc/php/7.0/fpm/pool.d/www.conf
# Create a /status path for your webserver in order to track current request
# You will need configurated as in this script Nginx server block in order for this to work
# Use IP/status to check PHP-FPM stats or IP/status?full&html for more detailed results
sed -i "s/^;pm.status_path = \/status/pm.status_path = \/status/" /etc/php/7.0/fpm/pool.d/www.conf
# Create a /ping path for your PHP-FPM installation in order to be able to make heartbeat calls to it
sed -i "s/^;ping.path = \/ping/ping.path = \/ping/" /etc/php/7.0/fpm/pool.d/www.conf
# Enable PHP-FPM Opcache
sed -i "s/^;opcache.enable=0/opcache.enable=1/" /etc/php/7.0/fpm/php.ini
# Set maximum memory limit for OPcache
sed -i "s/^;opcache.memory_consumption=64/opcache.memory_consumption=64/" /etc/php/7.0/fpm/php.ini
# Raise the maximum limit of variable that can be stored in OPcache
sed -i "s/^;opcache.interned_strings_buffer=4/opcache.interned_strings_buffer=16/" /etc/php/7.0/fpm/php.ini
# Set maximum amount fo files to be cached in OPcache
sed -i "s/^;opcache.max_accelerated_files=2000/opcache.max_accelerated_files=65536/" /etc/php/7.0/fpm/php.ini
# Enabled using directory path in order to avoid collision between two files with identical names in OPcache
sed -i "s/^;opcache.use_cwd=1/opcache.use_cwd=1/" /etc/php/7.0/fpm/php.ini
# Enable validation of changes in php files
sed -i "s/^;opcache.validate_timestamps=1/opcache.validate_timestamps=1/" /etc/php/7.0/fpm/php.ini
# Set validation period in seconds for OPcache file
sed -i "s/^;opcache.revalidate_freq=2/opcache.revalidate_freq=2/" /etc/php/7.0/fpm/php.ini
# Disable comments to be put in OPcache code
sed -i "s/^;opcache.save_comments=1/opcache.save_comments=0/" /etc/php/7.0/fpm/php.ini
# Enable fast shutdown
sed -i "s/^;opcache.fast_shutdown=0/opcache.fast_shutdown=1/" /etc/php/7.0/fpm/php.ini
# Set period in seconds in which PHP-FPM should restart if OPcache is not accessible
sed -i "s/^;opcache.force_restart_timeout=180/opcache.force_restart_timeout=30/" /etc/php/7.0/fpm/php.ini
# Reload Nginx installation
/etc/init.d/nginx reload 
# Reload PHP-FPM installation
/etc/init.d/php7.0-fpm reload
# Add a rule for iptables in order to make Monit be able to work on this port
iptables -A INPUT -p tcp -m tcp --dport 2812 -j ACCEPT
# Install a Monit service in order to maintain system fault tolerance
# Using ver. 1:5.16-2 because of the bug in the last version https://bugs.launchpad.net/ubuntu/+source/monit/+bug/1786910
apt-get install monit=1:5.16-2 -y -q
# Create a full backup of default Monit configuration
now=$(date +"%Y-%m-%d_%H-%M-%S") 
mkdir /backup/$now/
mkdir /backup/$now/monit/
cp -r /etc/monit/ /backup/$now/monit/
# Set time interval in which Monit will check the services
sed -i "s/^.*set daemon 120.*/set daemon 10/" /etc/monit/monitrc
# Set port on which Monit will be listening
sed -i "s/^#.*set httpd port 2812 and.*/set httpd port 2812 and/" /etc/monit/monitrc
# Set credentials for Monit to autentithicate itself on the server
sed -i "s/^#.*use address localhost.*/use address localhost/" /etc/monit/monitrc
sed -i "s/^#.*allow localhost.*/allow localhost/" /etc/monit/monitrc
sed -i "s/^#.*allow admin:monit.*/allow admin:monit/" /etc/monit/monitrc
# Tell monit to not search *.conf files in this directory
sed -i "s/^.*include \/etc\/monit\/conf-enabled\/\*/#include \/etc\/monit\/conf-enabled\/\*/" /etc/monit/monitrc
# Create a Monit configuration file to watch after PHP-FPM
# Monit will check the availability of php7.0-fpm.sock
# And restart php7.0-fpm service if it can't be accesible
# If Monit tries to many times to restart it withour success it will take a timeout and then procced to restart again
echo -e 'check process php7.0-fpm with pidfile /var/run/php/php7.0-fpm.pid\nstart program = "/etc/init.d/php7.0-fpm start"\nstop program = "/etc/init.d/php7.0-fpm stop"\nif failed unixsocket /run/php/php7.0-fpm.sock then restart\nif 5 restarts within 5 cycles then timeout' > /etc/monit/conf.d/php7.0-fpm.conf
# Create a Monit configuration file to watch after Nginx
# This one doesn't need Monit to restart it because Nginx is basically unbreakable
echo -e 'check process nginx with pidfile /var/run/nginx.pid\nstart program = "/etc/init.d/nginx start"\nstop program = "/etc/init.d/nginx stop"' > /etc/monit/conf.d/nginx.conf
# Create a Monit configuration file to watch after MariaDB
# Monit will check the availability of mysqld.sock
# And restart mysql service if it can't be accesible
# If Monit tries to many times to restart it withour success it will take a timeout and then procced to restart again
echo -e 'check process mysql with pidfile /run/mysqld/mysqld.pid\nstart program = "/usr/sbin/service mysql start"\nstop program  = "/usr/sbin/service mysql stop"\nif failed unixsocket /var/run/mysqld/mysqld.sock then restart\nif 5 restarts within 5 cycles then timeout' > /etc/monit/conf.d/mariadb.conf
# Create a Monit configuration file to watch after SSH
# This is a fool safe tool if you occasionally restarted ssh proccess and can't get into your server again
echo -e 'check process sshd with pidfile /var/run/sshd.pid\nstart program "/etc/init.d/ssh start"\nstop program "/etc/init.d/ssh stop"\nrestart program = "/etc/init.d/ssh restart"\nif failed port 22 protocol ssh then restart\nif 5 restarts within 5 cycles then timeout' > /etc/monit/conf.d/sshd.conf
# Create a Monit configuration file to watch after Memcached
echo -e 'check process memcached with match memcached\ngroup memcache\nstart program = "/etc/init.d/memcached start"\nstop program = "/etc/init.d/memcached stop"' > /etc/monit/conf.d/memcached.conf
# Reload main Monit configuration
update-rc.d monit enable
# Reload Monit in order to pickup new included *.conf files
monit reload
# Tell Monit to start all services
monit start all
# Tell Monit to Monitor all services
monit monitor all
# Get status of processes watched by Monit
monit status