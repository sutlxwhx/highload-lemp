#!/usr/bin/env bash
#
# Follow up commands are best suitable for clean Ubuntu 16.04 installation
# Nginx library is installed from custom ppa/ repository
# This will not be available for any other OS rather then Ubuntu
#
# Update list of available packages
apt-get update -y
# Update installed packages
apt-get dist-upgrade -y
# Install the most common packages that will be usefull under development environment
apt-get install zip unzip fail2ban htop sqlite3 nload mlocate nano python-software-properties software-properties-common -y
# Install Nginx && PHP-FPM stack
apt-get install php7.0-curl php7.0-fpm php7.0-gd php7.0-mbstring php7.0-mcrypt php7.0-opcache php7.0-xml php7.0-sqlite php7.0-mysql php-imagick -y
# Create a folder to backup current installation of Nginx && PHP-FPM
now=$(date +"%Y-%m-%d_%H-%M-%S") 
mkdir /backup/$now/
# Create a full backup of previous Nginx configuration
cp -r /etc/nginx/ /backup/$now/nginx/ 
# Create a full backup of previous PHP configuration
cp -r /etc/php/ /backup/$now/php/
# Delete previous Nginx installation
apt-get purge nginx-core nginx-common nginx -y
apt-get autoremove -y
# Add custom repository for Nginx
apt-add-repository ppa:hda-me/nginx-stable
# Update list of available packages
apt-get update -y
# Install custom Nginx package
apt-get install nginx -y
systemctl unmask nginx.service
# Install Brottli package for Nginx
apt-get install nginx-module-brotli -y
# Disable extrenal access to PHP-FPM scripts
sed -i "s/^;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.0/fpm/php.ini
# Create an additional configurational folder for Nginx
mkdir /etc/nginx/conf.d
# Download list of bad bots, bad ip's and bad referres
wget -O /etc/nginx/conf.d/blacklist.conf https://raw.githubusercontent.com/mariusv/nginx-badbot-blocker/master/blacklist.conf
wget -O /etc/nginx/conf.d/blockips.conf https://raw.githubusercontent.com/mariusv/nginx-badbot-blocker/master/blockips.conf
# Create default file for Nginx for where to find new websites that are pointed to this IP
echo -e 'server {\n\tlisten 80;\n\tserver_name $host;\n\troot /var/www/$host;\n\tindex index.php;\n\n\tlocation ~ \.php$ {\n\t\tinclude fastcgi-php.conf;\n\t\tinclude fastcgi_params;\n\t\tfastcgi_pass unix:/run/php/php7.0-fpm.sock;\n\t}\n\n\tlocation / {\n\t\tif ($bad_bot = 1) {return 503;}\n\t\tif ($bad_referer) {return 503;}\n\t\tif ($bad_urls1) {return 503;}\n\t\tif ($bad_urls2) {return 503;}\n\t\tif ($bad_urls3) {return 503;}\n\t\tif ($bad_urls4) {return 503;}\n\t\tif ($bad_urls5) {return 503;}\n\t\tif ($bad_urls6) {return 503;}\n\t\ttry_files $uri $uri/ /index.php?$args;\n\t}\n\n\tlocation ~ ^/(status|ping)$ {\n\t\tinclude fastcgi_params;\n\t\tfastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;\n\t\tfastcgi_pass unix:/run/php/php7.0-fpm.sock;\n\t}\n\n}' > /etc/nginx/sites-enabled/default
# Create fastcgi.conf
echo -e 'fastcgi_param  SCRIPT_FILENAME    $document_root$fastcgi_script_name;\nfastcgi_param  QUERY_STRING       $query_string;\nfastcgi_param  REQUEST_METHOD     $request_method;\nfastcgi_param  CONTENT_TYPE       $content_type;\nfastcgi_param  CONTENT_LENGTH     $content_length;\n\nfastcgi_param  SCRIPT_NAME        $fastcgi_script_name;\nfastcgi_param  REQUEST_URI        $request_uri;\nfastcgi_param  DOCUMENT_URI       $document_uri;\nfastcgi_param  DOCUMENT_ROOT      $document_root;\nfastcgi_param  SERVER_PROTOCOL    $server_protocol;\nfastcgi_param  HTTPS              $https if_not_empty;\n\nfastcgi_param  GATEWAY_INTERFACE  CGI/1.1;\nfastcgi_param  SERVER_SOFTWARE    nginx/$nginx_version;\n\nfastcgi_param  REMOTE_ADDR        $remote_addr;\nfastcgi_param  REMOTE_PORT        $remote_port;\nfastcgi_param  SERVER_ADDR        $server_addr;\nfastcgi_param  SERVER_PORT        $server_port;\nfastcgi_param  SERVER_NAME        $server_name;\n\n# PHP only, required if PHP was built with --enable-force-cgi-redirect\nfastcgi_param  REDIRECT_STATUS    200;' > /etc/nginx/fastcgi.conf
# Create fastcgi-php.conf
echo -e '# regex to split $uri to $fastcgi_script_name and $fastcgi_path\nfastcgi_split_path_info ^(.+\.php)(/.+)$;\n\n# Check that the PHP script exists before passing it\ntry_files $fastcgi_script_name =404;\n\n# Bypass the fact that try_files resets $fastcgi_path_info\n# see: http://trac.nginx.org/nginx/ticket/321\nset $path_info $fastcgi_path_info;\nfastcgi_param PATH_INFO $path_info;\n\nfastcgi_index index.php;\ninclude fastcgi.conf;' > /etc/nginx/fastcgi-php.conf
# Add repository for MariaDB 10.2
apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://ams2.mirrors.digitalocean.com/mariadb/repo/10.2/ubuntu xenial main'
# Update list of available packages
apt-get update -y
# Install MariaDB package
apt-get install mariadb-server -y
# Install Mysqltuner for future improvements of MariaDB installation
apt-get install mysqltuner -y
# Create default folder for future websites
mkdir /var/www
# Give Nginx permissions to be able to access these websites
chown -R www-data:www-data /var/www/*
# Find new files and add them to search index
updatedb
# Find the following file
locate www.conf
# Switch to ondemand state of PHP-FPM
pm = ondemand
# Use such number of children that will not hurt other parts of system
# Let's assume that the median amount of RAM that one PHP-FPM child proccess consumes is 32 MB
# Let's assume that system itself needs 128 MB of RAM
# Let's assume that wet let have MariaDB another 128 MB to run
# And finally let's assume that Nginx will need something like 8 MB to run
# On the 1 GB system that leads to 760 MB of free memory
# If we give one PHP-FPM child a moderate amount of RAM for example 32 MB that will let us create 23 PHP-FPM proccesses at max
ram=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
free=$(((ram/1024)-128-128-8))
php=$(((free/32)))
children=$(printf %.0f $php)
pm.max_children = $children
# State what amount of request one PHP-FPM child can sustain
pm.max_requests = 400
# State after what amount of time unused PHP-FPM children will stop
pm.process_idle_timeout = 10s;
# Create a /status path for your webserver in order to track current request
# You will need configurated as in this script Nginx server block in order for this to work
# Use IP/status or IP/status?full&html for more detailed results
/status
# Create a /ping path for your webserver in order to make heartbeat calls to it
/ping
# Reload Nginx installation
/etc/init.d/nginx reload 
# Reload PHP-FPM installation
/etc/init.d/php7.0-fpm reload
# Install a monit service in order to maintain system fault tolerance
apt-get install monit -y
# Create a full backup of defaul Monit configuration
cp -r /etc/monit/ /backup/$now/monit/
# Set time interval in which Monit will check the services
set daemon 10
# Set port on which Monit will be listening
set httpd port 2812 and
# Set credentials for Monit to autentithicate itself on the server
use address localhost  # only accept connection from localhost
allow localhost        # allow localhost to connect to the server and
allow admin:monit      # require user 'admin' with password 'monit'
# Add a rule for iptables in order to make Monit be able to work on this port
iptables -A INPUT -p tcp -m tcp --dport 2812 -j ACCEPT
# Create a monit configuration file to watch after PHP-FPM
# Monit will check the availability of php7.0-fpm.sock
# And restart php7.0-fpm service if it can't be accesible
# If monit tries to many times to restart it withour success it will take a timeout and then procced to restart again
echo -e 'check process php7.0-fpm with pidfile /var/run/php/php7.0-fpm.pid\nstart program = "/etc/init.d/php7.0-fpm start"\nstop program = "/etc/init.d/php7.0-fpm stop"\nif failed unixsocket /run/php/php7.0-fpm.sock then restart\nif 5 restarts within 5 cycles then timeout' > /etc/monit/conf.d/php7.0-fpm.conf
# Create a monit configuration file to watch after Nginx
# This one doesn't need Monit to restart it because Nginx is basically unbreakable
echo -e 'check process nginx with pidfile /var/run/nginx.pid\nstart program = "/etc/init.d/nginx start"\nstop program = "/etc/init.d/nginx stop"' > /etc/monit/conf.d/nginx.conf
# Create a monit configuration file to watch after MariaDB
# Monit will check the availability of mysqld.sock
# And restart mysql service if it can't be accesible
# If monit tries to many times to restart it withour success it will take a timeout and then procced to restart again
echo -e 'check process mysql with pidfile /run/mysqld/mysqld.pid\nstart program = "/usr/sbin/service mysql start"\nstop program  = "/usr/sbin/service mysql stop"\nif failed unixsocket /var/run/mysqld/mysqld.sock then restart\nif 5 restarts within 5 cycles then timeout' > /etc/monit/conf.d/mariadb.conf
# Create a monit configuration file to watch after SSH
# This is a fool safe tool if you occasionally restarted ssh proccess and can't get into your server again
echo -e 'check process sshd with pidfile /var/run/sshd.pid\nstart program "/etc/init.d/ssh start"\nstop program "/etc/init.d/ssh stop"\nrestart program = "/etc/init.d/ssh restart"\nif failed port 22 protocol ssh then restart\nif 5 restarts within 5 cycles then timeout' > /etc/monit/conf.d/sshd.conf
# Create a monit configuration file to watch after Memcached
echo -e 'check process memcached with match memcached\ngroup memcache\nstart program = "/etc/init.d/memcached start"\nstop program = "/etc/init.d/memcached stop"' > /etc/monit/conf.d/memcached.conf
# Reload main monit configuration
update-rc.d monit enable
# Reload monit in order to pickup new included *.conf files
monit reload
# Tell monit to start all services
monit start all
# Tell monit to monitor all services
monit monitor all