# -*- mode: ruby -*-
# vi: set ft=ruby :

$script = <<SHELL
  yum install -y vim ntpdate
  ntpdate 0.pool.ntp.org
  (crontab -l ; echo '* * * * * /usr/sbin/ntpdate 0.pool.ntp.org') | crontab -
  curl -sL https://git.io/vbsTg | alces_OS=el7 bash
SHELL

Vagrant.configure("2") do |config|
  config.vm.box = 'centos/7'
  config.vm.hostname = 'controller'
  config.vm.provision "shell", inline: $script
  config.vm.provision "file",
                      source: "~/.cloudware.yml",
                      destination: "~vagrant/.cloudware.yml"
end
