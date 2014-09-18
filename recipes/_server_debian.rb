#----
# Create essential directories
#----

directory node['mysql']['data_dir'] do
  owner     'mysql'
  group     'mysql'
  action    :create
  recursive  true
end

node['mysql']['server']['directories'].each do |key, value|
  directory value do
    owner     'mysql'
    group     'mysql'
    mode      '0775'
    recursive  true
    action    :create
  end
end

#----
# Set up preseeding data for debian packages
#----

directory '/var/cache/local/preseeding' do
  owner     'root'
  group     'root'
  mode      '0755'
  recursive  true
end

template '/var/cache/local/preseeding/mysql-server.seed' do
  source   'mysql-server.seed.erb'
  owner    'root'
  group    'root'
  mode     '0600'
  notifies :run, 'execute[preseed mysql-server]', :immediately
end

# Debug only:
#
package 'debconf-utils' do
  action :install
  only_if { node['mysql']['debug'] }
end

execute 'check for password' do
  command '/usr/bin/debconf-get-selections | grep -E "(mysql|galera)-server.+/root_password.*\s+select\s+"'
  only_if { node['mysql']['debug'] }
end
#
# End debug

#----
# Install software
#----

# Either the apt cookbook doesn't pass-through environment variables, or dpkg
# ignores them during installation.  Either way, this unfortunately doesn't
# work :(
#
#ENV['DEBIAN_SCRIPT_DEBUG'] = '1'
#ENV['MYSQLD_STARTUP_TIMEOUT'] = '120'

# We kinda need this, though, so let's set it and hope for the best!
# N.B. This is used by dpkg itself, rather than invoked init scripts, so
# there's a better chance it'll be adhered to...
#
ENV['DEBIAN_FRONTEND'] = 'noninteractive'

node['mysql']['server']['packages'].each do |name|
  package name do
    # NB: '-o Debug::pkgDPkgPM="true"' doesn't appear to show dpkg
    #     command-invocations, but does prevent package installation...

    options '-o DPkg::NoTriggers="true" '           + \
            '-o PackageManager::Configure="smart" ' + \
            '-o DPkg::ConfigurePending="false" '    + \
            '-o DPkg::TriggersPending="false" '     + \
            '-o DPkg::options="{'                   + \
              '\"--debug=10043\"; '                 + \
              '\"--force-confnew\"; '               + \
              '\"--force-confdef\"; '               + \
            '};"'
    action :install
  end
end

#----
# Configuration deployment
#----

if( ( node['mysql']['implementation'].eql?('mariadb') ) or ( node['mysql']['implementation'].eql?('galera') ) )

  cookbook_file '/etc/init.d/mysql' do # ~FC009
    path          '/etc/init.d/mysql.dpkg-new'
    source        'mysql.initd'
    owner         'root'
    group         'root'
    mode          '0755'
    atomic_update  true
    backup         false
  end

  if( node['mysql']['implementation'].eql?('galera') )
    template 'Cluster settings' do
      path     '/etc/mysql/conf.d/galera.cnf'
      if( node['mysql']['galera']['cluster']['master'] )
        source 'master_galera.cnf.erb'
      else
        source 'node_galera.cnf.erb'
      end
      owner    'root'
      group    'mysql'
      mode     '0640'
    end
  end

else # not( ( node['mysql']['implementation'].eql?('mariadb') ) or ( node['mysql']['implementation'].eql?('galera') ) )

  template '/etc/init/mysql.conf' do
    source   'init-mysql.conf.erb'
    only_if { node['platform_family'].eql?('ubuntu') }
  end

  template '/etc/apparmor.d/usr.sbin.mysqld' do
    source   'usr.sbin.mysqld.erb'
    action   :create
    notifies :reload, 'service[apparmor-mysql]', :immediately
  end

end

template '/etc/mysql/debian.cnf' do
  source   'debian.cnf.erb'
  owner    'root'
  group    'root'
  mode     '0600'
end

template '/etc/mysql/my.cnf' do
  source   'my.cnf.erb'
  owner    'root'
  group    'root'
  mode     '0644'
  notifies :run, 'bash[move mysql data to datadir]', :immediately
end

#----
# data_dir
#----

# DRAGONS!
# Setting up data_dir will only work on initial node converge...
# Data will NOT be moved around the filesystem when you change data_dir
# To do that, we'll need to stash the data_dir of the last chef-client
# run somewhere and read it. Implementing that will come in "The Future"
#
# don't try this at home
# http://ubuntuforums.org/showthread.php?t=804126
#
# N.B. 'stat -c %h' gives the (hard-)link count for a specified file or
#      directory, which will return "2" ('.' and '..') for an empty directory...
#      unless you're using btrfs which returns that *actual* hard-link count
#      for the directory, and therefore will almost always return "1".
#
#  only_if "[ `stat -c %h #{node['mysql']['data_dir']}` -eq 2 ]"
#  not_if  '[ `stat -c %h /var/lib/mysql/` -eq 2 ]'
#
bash 'move mysql data to datadir' do
  user 'root'
  code <<-EOH
  mv /var/lib/mysql/* #{node['mysql']['data_dir']}/
  EOH
  action :nothing
  only_if "[ '/var/lib/mysql' != #{node['mysql']['data_dir']} ]"
  only_if "[ `ls -1A #{node['mysql']['data_dir']}/` -eq 0 ]"
  not_if  '[ `ls -1A /var/lib/mysql/` -eq 0 ]'
end

#----
# Configure and start database
#----

execute 'dpkg-configure-pending' do
  command  'dpkg --configure --pending --debug=10043 --force-confnew --force-confdef'
end

# 'mysql_upgrade should be invoked by the post-install scripts on Debian...
#
execute 'mysql_upgrade' do
  command        "mysql_upgrade -u root -p#{ node['mysql']['server_root_password'] }"
  ignore_failure  true
  not_if { node['platform_family'].eql?('ubuntu') or node['platform_family'].eql?('debian') }
end

#----
# Grants
#----

grants = '/etc/mysql_grants.sql'
template grants do
  source   'grants.sql.erb'
  owner    'root'
  group    'root'
  mode     '0600'
  if( not( ( node['mysql']['implementation'].eql?('galera') ) and ( node['mysql']['galera']['cluster']['enabled'] ) and not( node['mysql']['galera']['cluster']['master'] ) ) )
    notifies :run, 'execute[install-grants]', :immediately
  end
end

cmd = install_grants_cmd
log 'galera-grants' do
  message 'Default users are not provisioned on non-initiating galera cluster' +
          "members: Start the cluster (with 'SET GLOBAL wsrep_provider_options" +
          '="pc.bootstrap=true";' + "'), then load grants from '#{grants}' " +
          "with command '#{cmd}' if necessary"
  level   :warn
  only_if { ( node['mysql']['implementation'].eql?('galera') ) and ( node['mysql']['galera']['cluster']['enabled'] and not( node['mysql']['galera']['cluster']['master'] ) ) }
end


#----
# Redeploy master galera.cnf, so as not to create a new cluster on restart of initiator node
#----

if( ( node['mysql']['implementation'].eql?('galera') ) and ( node['mysql']['galera']['cluster']['enabled'] ) and ( node['mysql']['galera']['cluster']['master'] ) )

  log 'galera-initiator' do
    message 'The Galera master configuration data in "/etc/mysql/conf.d/galera.cnf" ' +
            'is now being replaced with a version which allows the node designated ' +
            '"master" to re-join an existing cluster.  If this process fails, then ' +
            'a new cluster can be started (from any node) by invoking: ' +
            '"/etc/init.d/mysql start --wsrep-cluster-address=gcomm://"'
    level   :warn
  end

  template 'Remove initiator cluster creation' do
    path     '/etc/mysql/conf.d/galera.cnf'
    source   'node_galera.cnf.erb'
    owner    'root'
    group    'mysql'
    mode     '0640'
  end

end

#----
# Services & Helpers
#----

execute 'preseed mysql-server' do
  command '/usr/bin/debconf-set-selections /var/cache/local/preseeding/mysql-server.seed'
  action  :nothing
end

execute 'install-grants' do
  command  cmd
  action  :nothing
end

service 'apparmor-mysql' do
  provider = Chef::Provider::Service::Init::Debian
  service_name 'apparmor'
  action       :nothing
  supports     :reload => true
end

service 'mysql' do
  service_provider = Chef::Provider::Service::Init::Debian
  if node['mysql']['implementation'] != 'mariadb' && node['mysql']['implementation'] != 'galera'
    service_provider = Chef::Provider::Service::Upstart if(
      ( node['platform'].eql?('ubuntu') ) and ( Chef::VersionConstraint.new('>= 13.10').include?(node['platform_version']) )
    )
  end
  provider      service_provider
  service_name 'mysql'
  supports     :status => true, :restart => true, :reload => true
  action      [:enable, :start]
end
