# -*- mode: ruby -*-
# vi: set ft=ruby :

$script = <<SHELL
  echo 'sudo su -' > /home/vagrant/.bashrc
  mv /home/vagrant/.cloudware.yml /root/.cloudware.yml
  yum install -y vim ntpdate
  ntpdate 0.pool.ntp.org
  (crontab -l ; echo '* * * * * /usr/sbin/ntpdate 0.pool.ntp.org') | crontab -
  curl -sL https://git.io/vbsTg | alces_OS=el7 bash
SHELL

Vagrant.configure("2") do |config|
  config.vm.box = 'centos/7'
  config.vm.hostname = 'controller'
  config.vm.synced_folder '.', '/vagrant', disabled: true
  config.vm.synced_folder '.', '/tmp/cloudware', type: 'rsync'
  config.vm.provision "file",
                      source: "~/.cloudware.yml",
                      destination: "~/.cloudware.yml"
  config.vm.provision "shell", inline: $script
end
