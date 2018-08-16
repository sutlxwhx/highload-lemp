# Highload LEMP Installation

This bash script will install LEMP stack on your Ubuntu and configure it to maximize its performance.

## Features
* All-in-one one click installation of the [LEMP](https://en.wikipedia.org/wiki/LAMP_(software_bundle)) environment
* Nginx will be installed with all available modules, you just need to turn them on
* I went through [Nginx](https://nginx.org/en/docs/http/ngx_http_core_module.html) docs and customised default variables for maximum Nginx perfomance while adding new configuration lines
* I went through [MariaDB](https://mariadb.com/kb/en/library/server-system-variables/) docs and customised default variables for maximum MariaDB perfomance while adding new configuration lines
* [Monit](https://mmonit.com/monit/) will be used to maximize LEMP fault taulerance
* This configurated was tested in heavy loaded environment (>500k requests to a webserver a day)
* Don't struggle anymore with adding new server blocks to Nginx when you add new website to your server

## Getting started
Every command is well commented so you will know what will happend after each line of code. Feel free to modify this bash script and to add new OS / Platform support.

## Requirements
* Ubuntu 16.04 or later

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
For example you created an A-record in your DNS panel where you pointed '@' name of 'test.com' domain to '1.2.3.4' IP adress of your server. IF you will try to access 'test.com' LEMP will try to use index.php / index.html files to open in your /var/www/test.com directory.

This script will create 'Hello World' website in /var/www/test.com and phpinfo file at /var/www/test.com/info.php

You can verify the installation with this info.php or use the following commands:
```shell
nginx -V
```
This will show current Nginx version and all installed Nginx modules.
```shell
php -v
php -m
```
This will show current PHP-FPM version all installed PHP-FPM modules.
```shell
mysql -v
EXIT;
```
This will show current MariaDB version and promt EXIT; command if you entered MariaDB shell.

## Developing
Please, feel free to fork this repository and add support for your OS. It will greatly help developers who prefer another OS / Platforms. I' am not doing this myself because I found that using prebuilt custom Ubuntu repository makes usage of this script endlessly faster with less head pain then trying to define why Nginx package is not compiling from the source code on another particular OS / Platform.

## Licensing

The code in this project is licensed under Apache License 2.0