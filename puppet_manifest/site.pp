#class {'testing':}
#class {'user_profile':}
class {'redis_server':}
#class {'profile::vim':}

# install rubies from binaries
Rvm_system_ruby {
  ensure     => present,
  build_opts => ['--binary'],
}

 
class { 'rvm': }
#rvm::system_user { 'vagrant': }
rvm_system_ruby {
  'ruby-1.9.3':;
  'ruby-2.0.0':
    default_use => true;
  #  'jruby':;
}
