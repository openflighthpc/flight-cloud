# -*- mode: ruby -*-
# vi: set ft=ruby :

$src_dir = '/tmp/cloudware'
$script = <<SHELL
  echo 'sudo su -' > /home/vagrant/.bashrc
  mv /home/vagrant/.cloudware.yml /root/.cloudware.yml
  echo 'cd #{$src_dir}' >> /root/.bashrc
  yum install -y vim ntpdate
  ntpdate 0.pool.ntp.org
  (crontab -l ; echo '* * * * * /usr/sbin/ntpdate 0.pool.ntp.org') | crontab -
  bash "#{File.join($src_dir, 'scripts/install')}" "el7"
SHELL

Vagrant.configure("2") do |config|
  config.vm.box = 'centos/7'
  config.vm.hostname = 'controller'
  config.vm.synced_folder '.', '/vagrant', disabled: true
  config.vm.synced_folder '.', $src_dir, type: 'rsync'
  config.vm.provision "file",
                      source: "~/.cloudware.yml",
                      destination: "~/.cloudware.yml"
  config.vm.provision "shell", inline: $script
end
