#
# Cookbook Name:: mysql
# Attributes:: default
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

# Enable additional debugging routines:
#
default['mysql']['debug'] = false

# Select MySQL implementation:
#  - mariadb : MariaDB 5.5 unclustered server, MariaDB client
#  - galera  : MariaDB 5.5 Galera server, MariaDB client
#  - percona : Percona server, MySQL client [incomplete, unsupported]
#  - mysql   : Oracle MySQL server, MySQL client
#
default['mysql']['implementation'] = 'mysql'

# Potential future enhancement - would this ever be of any benefit?
#
#default['mysql']['implementation']['client'] = 'mariadb'
#default['mysql']['implementation']['server'] = 'galera'

# ... on the other hand, this *would* be very useful
#
#default['mysql']['implementation']['master'] = 'galera'
#default['mysql']['implementation']['slave'] = 'mariadb'

