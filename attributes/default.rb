#
# Cookbook Name:: mysql
# Attributes:: default
#

#
# HP Autonomy IOD-specific MySQL SSL Configs
#

#
# Copyright 2014, Stuart Shelton, HP Autonomy
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Select MySQL implementation:
#  - mariadb : MariaDB 5.5 unclustered server, MariaDB client
#  - galera  : MariaDB 5.5 Galera server, MariaDB client
#  - percona : Percona server, MySQL client [incomplete, unsupported]
#  - mysql   : Oracle MySQL server, MySQL client
default['mysql']['implementation'] = 'mysql'

# For future enhancement:
#default['mysql']['implementation']['client'] = 'mariadb'
#default['mysql']['implementation']['server'] = 'galera'

default['mysql']['mariadb']['apt_keyserver'] = 'hkp://keyserver.ubuntu.com:80'
default['mysql']['mariadb']['apt_key_id'] = '1BB943DB'
#default['mysql']['mariadb']['apt_uri'] = 'http://mirror.jmu.edu/pub/mariadb/repo/5.5/ubuntu'
default['mysql']['mariadb']['apt_uri'] = 'http://ftp.osuosl.org/pub/mariadb/repo/5.5/ubuntu'

default['mysql']['use_ssl'] = true
default['mysql']['cert_file'] = "cert.pem"
default['mysql']['key_file'] = "key.pem"
default['mysql']['ssl_ca'] = nil

#
# End HP Autonomy IOD-specific
#

default['mysql']['service_name'] = 'default'

# passwords
default['mysql']['server_root_password'] = 'ilikerandompasswords'
default['mysql']['server_debian_password'] = 'postinstallscriptsarestupid'

case node['platform']
when 'smartos'
  default['mysql']['data_dir'] = '/opt/local/lib/mysql'
else
  default['mysql']['data_dir'] = '/var/lib/mysql'
end

# port
default['mysql']['port'] = '3306'

# used in grants.sql
default['mysql']['allow_remote_root'] = false
default['mysql']['remove_anonymous_users'] = true
default['mysql']['root_network_acl'] = nil
