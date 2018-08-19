# Highload LEMP Installation

This bash script will install LEMP stack on your Ubuntu and configure it to maximize its performance.

## Features
* All-in-one one click installation of the [LEMP](https://en.wikipedia.org/wiki/LAMP_(software_bundle)) environment
* Nginx will be installed with the ability to dynamically load or disable any available module
* I went through [Nginx](https://nginx.org/en/docs/http/ngx_http_core_module.html) docs and customised default variables for maximum Nginx perfomance while adding new configuration lines
* I went through [MariaDB](https://mariadb.com/kb/en/library/server-system-variables/) docs and customised default variables for maximum MariaDB perfomance while adding new configuration lines
* [Monit](https://mmonit.com/monit/) will be used to maximize LEMP fault taulerance
* This configuration was tested in heavy loaded environment (>500k requests to a webserver a day)
* Don't struggle anymore with adding new server blocks to Nginx when you add new websites to your server

## Getting started
Every command is well commented so you will know what will happend after each line of code. Feel free to modify this bash script and to add new OS / Platform support.

## Requirements
* Ubuntu 16.04 or later (best if it's fresh / clean installation)
* This script utilises **root** user privileges. If you run it from another user you need to add this user to sudoers group and prepend sudo to all commands in the script.

## Usage

To download and run this script in a single command use the line below:
```shell
wget https://raw.githubusercontent.com/sutlxwhx/Highload-LEMP-Installation/master/install.sh && bash install.sh
```
Or download install.sh manually, make it executable and run it:
```shell
wget https://raw.githubusercontent.com/sutlxwhx/Highload-LEMP-Installation/master/install.sh
chmod +x install.sh
./install.sh
```
LEMP will be configured in such a way that it will try to find a folder which is identical to a website name in your /var/www directory.
For example you created an A-record in your DNS panel where you pointed '@' name of 'test.com' domain to '1.2.3.4' IP adress of your server. If you will try to access 'test.com' LEMP will try to use index.php / index.html files to open in your /var/www/test.com directory.

**MariaDB password** is generated using md5 hash of your server hostname and will be put in your /etc/mysql/my.cnf after [client] directive. 

## Test files that will be created

* "Hello World" website in /var/www/test.com 
* phpinfo(); file at /var/www/test.com/info.php
* [opcache.php](https://github.com/rlerdorf/opcache-status) at /var/www/test.com/opcache.php

## Verification

You can verify the installation with the info.php file or using the following commands:
```shell
nginx -V
```
This will show current Nginx version and all installed Nginx modules.
```shell
php -v
php -m
```
These will show current PHP-FPM version all installed PHP-FPM modules.
```shell
mysql -v
EXIT;
```
These will show current MariaDB version and promt EXIT; command if you entered MariaDB shell.

## Developing
Please, feel free to fork this repository and add support for your OS. It will greatly help developers who prefer another OS / Platforms. I' am not doing this myself because I found that using prebuilt custom Ubuntu repository makes usage of this script endlessly faster with less head pain then trying to define why Nginx package is not compiling from the source code on another particular OS / Platform.

## Licensing

The code in this project is licensed under Apache License 2.0