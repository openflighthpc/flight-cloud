# -*- mode: ruby -*-
# vi: set ft=ruby :

$src_dir = '/tmp/cloudware'
$script = <<SHELL
  echo 'sudo su -' > /home/vagrant/.bashrc
  mv /home/vagrant/.flightconnector.yml /root/.flightconnector.yml
  echo 'cd #{$src_dir}' >> /root/.bashrc
  yum install -y vim tree
  rm -rf #{$src_dir}/tmp # Remove the old build logs
  bash "#{File.join($src_dir, 'scripts/install')}" "el7"
  echo 'PATH=/opt/cloudware/opt/ruby/bin:$PATH' >> /root/.bashrc
SHELL

Vagrant.configure('2') do |config|
  config.vm.box = 'hfm4/centos7'
  config.vm.hostname = 'controller'
  config.vm.synced_folder '.', '/vagrant', disabled: true
  config.vm.synced_folder '.', $src_dir
  config.vm.provision 'file',
                      source: '~/.flightconnector.yml',
                      destination: '~/.flightconnector.yml'
  config.vm.provision 'shell', inline: $script
end
