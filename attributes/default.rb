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

# Select MySQL implementation:
#  - mariadb : MariaDB 5.5 unclustered server, MariaDB client
#  - galera  : MariaDB 5.5 Galera server, MariaDB client
#  - percona : Percona server, MySQL client [incomplete, unsupported]
#  - mysql   : Oracle MySQL server, MySQL client
default['mysql']['implementation'] = 'mysql'

# For future enhancement:
#default['mysql']['implementation']['client'] = 'mariadb'
#default['mysql']['implementation']['server'] = 'galera'

#
# Galera configuration:
#

# Dynamic-configuration approach:
#  One node is 'master' - this must detect whether there is an existing cluster
#  which is dropped-out from, and then rejoin this if it is running.  Otherwise
#  the master (only) needs to run '--wsrep-new-cluster' in order to establish a
#  new cluster for other nodes to join.
# Namely, the master is fixed but the nodes are dynamic (but from a list or DNS)
#
# Static-configuration approach:
#  All nodes are pre-declared before any are started, and are all started with:
#    --wsrep_cluster_address=gcomm://node1,node2,...,nodex?pc.wait_prim=no
#  after which "SET GLOBAL wsrep_provider_options='bc.bootstrap=true';" can be
#  executed on any node to start the cluster.
# Namely, the nodes are fixed but the cluster-initiator is dynamic, and there
# is no real concept of a 'master'.
#
# The MariaDB project documents the Static approach as 'good practice'.
#

default['mysql']['galera']['cluster']['approach'] = 'static'
#default['mysql']['galera']['cluster']['approach'] = 'dynamic'

#
# Galera Dynamic approach configuration:
#

# Should hosts for the Dynamic approach come from DNS, or from the hosts list
# below?
#default['mysql']['galera']['cluster']['dynamic']['method'] = 'list'
default['mysql']['galera']['cluster']['dynamic']['method'] = 'dns'

# What DNS hostname can a lookup be performed upon to determine cluster nodes?
default['mysql']['galera']['cluster']['dynamic']['lookup'] = 'galera-cluster-members'

# Which instance should run '--wsrep-new-cluster' on startup?
default['mysql']['galera']['cluster']['dynamic']['master'] = 'localhost'

#
# Galera shared configuration:
#

# Cluster name
default['mysql']['galera']['cluster']['name'] = 'db-cluster'

# State-transfer method
default['mysql']['galera']['cluster']['sst'] = 'rsync'
#default['mysql']['galera']['cluster']['sst'] = 'mysqldump'
#default['mysql']['galera']['cluster']['sst'] = 'xtrabackup'
#default['mysql']['galera']['cluster']['sst'] = 'xtrabackup-v2'

# For a Static approach or a Dynamic approach using the 'list' method, what
# nodes will be in the cluster?
#
# N.B. It is critically important that this value is accurate, and an array!
#
default['mysql']['galera']['cluster']['hosts'] = ['localhost']

# Are we running garbd (Galera Arbitrator daemon) and, if so, where?
default['mysql']['galera']['cluster']['garbd']['enabled'] = true
default['mysql']['galera']['cluster']['garbd']['host'] = 'localhost'

