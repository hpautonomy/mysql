#
# Cookbook Name:: mysql
# Attributes:: client
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

default['mysql']['mariadb']['apt_keyserver'] = 'hkp://keyserver.ubuntu.com:80'
default['mysql']['mariadb']['apt_key_id'] = '1BB943DB'
#default['mysql']['mariadb']['apt_uri'] = 'http://mirror.jmu.edu/pub/mariadb/repo/5.5/ubuntu'
default['mysql']['mariadb']['apt_uri'] = 'http://ftp.osuosl.org/pub/mariadb/repo/5.5/ubuntu'
