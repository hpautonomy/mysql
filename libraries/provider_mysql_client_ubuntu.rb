require 'chef/provider/lwrp_base'

class Chef
  class Provider
    class MysqlClient
      class Ubuntu < Chef::Provider::MysqlClient
        use_inline_resources if defined?(use_inline_resources)

        def whyrun_supported?
          true
        end

        pkgs = %w(mysql-client libmysqlclient-dev)
        if node['mysql']['implementation'] == 'mariadb' || node['mysql']['implementation'] == 'galera'
          include_recipe 'apt::default'

          apt_repository 'mariadb' do
            uri          node[ 'mysql' ][ 'mariadb' ][ 'apt_uri']
            distribution node[ 'lsb' ][ 'codename' ]
            components   %w(main)
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

          pkgs = %w(mariadb-client libmariadbclient-dev)
        end

        action :create do
          converge_by 'ubuntu pattern' do
            pkgs.each do |p|
              package p do
                action :install
              end
            end
          end
        end

        action :delete do
          converge_by 'ubuntu pattern' do
            pkgs.each do |p|
              package p do
                action :remove
              end
            end
          end
        end
      end
    end
  end
end

Chef::Platform.set :platform => :ubuntu, :resource => :mysql_client, :provider => Chef::Provider::MysqlClient::Ubuntu
