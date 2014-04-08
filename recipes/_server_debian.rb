#----
# Set up preseeding data for debian packages
#---
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

execute 'preseed mysql-server' do
  command '/usr/bin/debconf-set-selections /var/cache/local/preseeding/mysql-server.seed'
  action  :nothing
end

if node['mysql']['implementation'] != 'mariadb' && node['mysql']['implementation'] != 'galera'

  node['mysql']['server']['packages'].each do |name|
    package name do
      action :install
    end
  end

else

  #----
  # Install software
  #----

  # Either the apt cookbook doesn't pass-through environment variables, or dpkg
  # ignores them during installation.  Either way, this unfortunately doesn't
  # work :(
  #ENV['DEBIAN_SCRIPT_DEBUG'] = '1'
  #ENV['MYSQLD_STARTUP_TIMEOUT'] = '120'

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

  cookbook_file '/etc/init.d/mysql' do
    path          '/etc/init.d/mysql.dpkg-new'
    source        'mysql.initd'
    owner         'root'
    group         'root'
    mode          '0755'
    atomic_update  true
    backup         false
  end

  if node['mysql']['implementation'] == 'galera'
    template '/etc/mysql/conf.d/galera.cnf' do
      source   'galera.cnf.erb'
      owner    'root'
      group    'root'
      mode     '0644'
    end
  end

  execute 'dpkg-configure-pending' do
    command  'dpkg --configure --pending --debug=10043 --force-confnew --force-confdef'
  end
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
# Grants
#----
template '/etc/mysql_grants.sql' do
  source   'grants.sql.erb'
  owner    'root'
  group    'root'
  mode     '0600'
  notifies :run, 'execute[install-grants]', :immediately
end

cmd = install_grants_cmd
execute 'install-grants' do
  command  cmd
  action  :nothing
end

template '/etc/mysql/debian.cnf' do
  source   'debian.cnf.erb'
  owner    'root'
  group    'root'
  mode     '0600'
  notifies :reload, 'service[mysql]'
  # HP Autonomy IOD-specific
  # ':reload' action is thought to be unreliable...
  #notifies :restart, 'service[mysql]', :immediately
  # End HP Autonomy IOD-specific
end

#----
# data_dir
#----

# DRAGONS!
# Setting up data_dir will only work on initial node converge...
# Data will NOT be moved around the filesystem when you change data_dir
# To do that, we'll need to stash the data_dir of the last chef-client
# run somewhere and read it. Implementing that will come in "The Future"

directory node['mysql']['data_dir'] do
  owner     'mysql'
  group     'mysql'
  action    :create
  recursive  true
end

if node['mysql']['implementation'] != 'mariadb' && node['mysql']['implementation'] != 'galera'
  template '/etc/init/mysql.conf' do
    source   'init-mysql.conf.erb'
    only_if { node['platform_family'] == 'ubuntu' }
  end

  template '/etc/apparmor.d/usr.sbin.mysqld' do
    source   'usr.sbin.mysqld.erb'
    action   :create
    notifies :reload, 'service[apparmor-mysql]', :immediately
  end

  service 'apparmor-mysql' do
    service_name 'apparmor'
    action       :nothing
    supports     :reload => true
  end
end

template '/etc/mysql/my.cnf' do
  source   'my.cnf.erb'
  owner    'root'
  group    'root'
  mode     '0644'
  notifies :run,     'bash[move mysql data to datadir]', :immediately
  notifies :reload,  'service[mysql]'
  # HP Autonomy IOD-specific immediate restart
  #notifies :restart, 'service[mysql]', :immediately
  # End HP Autonomy IOD-specific
end

# don't try this at home
# http://ubuntuforums.org/showthread.php?t=804126
bash 'move mysql data to datadir' do
  user 'root'
  if node['mysql']['implementation'] == 'mariadb' || node['mysql']['implementation'] == 'galera'
    code <<-EOH
    /etc/init.d/mysql stop &&
    mv /var/lib/mysql/* #{node['mysql']['data_dir']} &&
    /etc/init.d/mysql start
    EOH
  else
    code <<-EOH
    /usr/sbin/service mysql stop &&
    mv /var/lib/mysql/* #{node['mysql']['data_dir']} &&
    /usr/sbin/service mysql start
    EOH
  end
  action :nothing
  only_if "[ '/var/lib/mysql' != #{node['mysql']['data_dir']} ]"
  only_if "[ `stat -c %h #{node['mysql']['data_dir']}` -eq 2 ]"
  not_if  '[ `stat -c %h /var/lib/mysql/` -eq 2 ]'
end

if node['mysql']['implementation'] == 'mariadb' || node['mysql']['implementation'] == 'galera'
  service_provider = Chef::Provider::Service::Init::Debian if 'ubuntu' == node['platform']
else
  service_provider = Chef::Provider::Service::Upstart if 'ubuntu' == node['platform'] &&
    Chef::VersionConstraint.new('>= 13.10').include?(node['platform_version'])
end

service 'mysql' do
  provider service_provider
  service_name 'mysql'
  supports     :status => true, :restart => true, :reload => true
  action      [:enable, :start]
end
