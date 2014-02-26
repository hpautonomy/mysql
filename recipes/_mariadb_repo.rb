#
# Cookbook Name:: mysql
# Recipe:: mariadb_repo
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

case node[ 'platform_family' ]
  when 'debian'
    include_recipe 'apt::default'

    apt_repository 'mariadb' do
      uri          node[ 'mysql' ][ 'mariadb' ][ 'apt_uri']
      distribution node[ 'lsb' ][ 'codename' ]
      components   %w[ main ]
      keyserver    node[ 'mysql' ][ 'mariadb' ][ 'apt_keyserver' ]
      key          node[ 'mysql' ][ 'mariadb' ][ 'apt_key_id' ]
      action       :add
    end

    apt_preference 'mariadb' do
      glob         '*'
      pin          "origin #{ node[ 'mysql' ][ 'mariadb' ][ 'apt_uri'] }"
      pin_priority '1000'
      action       :add
    end
end
