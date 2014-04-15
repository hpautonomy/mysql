#
# Cookbook Name:: mysql
# Attributes:: galera
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

#
# Galera configuration:
#

default['mysql']['galera']['cluster']['enabled'] = false
default['mysql']['galera']['cluster']['debug'] = 'ON'

# Cluster name
#
default['mysql']['galera']['cluster']['name'] = 'db-cluster'

# Should the current instance should run '--wsrep-new-cluster' on startup?
#
# Override this on *one* node only!
#
default['mysql']['galera']['cluster']['master'] = false

# State-transfer method
#
default['mysql']['galera']['cluster']['sst']['method'] = 'rsync'
#default['mysql']['galera']['cluster']['sst']['method'] = 'mysqldump'
#default['mysql']['galera']['cluster']['sst']['method'] = 'xtrabackup'
#default['mysql']['galera']['cluster']['sst']['method'] = 'xtrabackup-v2'
default['mysql']['galera']['cluster']['sst']['auth'] = "root:#{ node['mysql']['server_root_password'] }"

# Are we running garbd (Galera Arbitrator daemon) and, if so, where?
#
default['mysql']['galera']['cluster']['garbd']['enabled'] = false
default['mysql']['galera']['cluster']['garbd']['host'] = 'localhost'

# What nodes will form this cluster?
#
# N.B. It is critically important that this value is accurate (and an array)!
#
default['mysql']['galera']['cluster']['hosts'] = ['localhost']

