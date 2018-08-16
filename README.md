# Highload LEMP Installation

## Features
* All-in-one one click installation of the [LEMP](https://en.wikipedia.org/wiki/LAMP_(software_bundle)) environment
* Nginx will be installed with all available modules, you just need to turn them on
* I went through [Nginx](https://nginx.org/en/docs/http/ngx_http_core_module.html) docs and customised default variables for maximum Nginx perfomance while adding new configuration lines
* I went through [MariaDB](https://mariadb.com/kb/en/library/server-system-variables/) docs and customised default variables for maximum MariaDB perfomance while adding new configuration lines
* [Monit](https://mmonit.com/monit/) will be used to maximize LEMP fault taulerance
* This configurated was tested in heavy loaded environment (>500k requests to a webserver a day)

## Getting started
Every command is well commented so you will know what will happend after each line of code. Feel free to modify this bash script and to add new OS / Platform support.

## Requirements
* Ubuntu 16.04 or later

## Usage

To download and run this script in a single command use the line below:
```shell
wget https://raw.githubusercontent.com/sutlxwhx/Highload-LEMP-Installation/master/install.sh | bash install.sh
```
Or download install.sh manually, make it executable and run it:
```shell
wget https://raw.githubusercontent.com/sutlxwhx/Highload-LEMP-Installation/master/install.sh
chmod +x install.sh
./install.sh
```

## Developing
Please, feel free to fork this repository and add support for your OS. It will greatly help developers who prefer another OS / Platforms. I' am not doing this myself because I found that using prebuilt custom Ubuntu repository makes usage of this script endlessly faster with less head pain then trying to define why Nginx package is not compiling from the source code on another particular OS / Platform.

## Licensing

The code in this project is licensed under Apache License 2.0