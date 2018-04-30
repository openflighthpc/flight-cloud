# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure("2") do |config|
  config.vm.box = 'centos/7'
  config.vm.hostname = 'controller'
  config.vm.provision "shell", inline: <<-SHELL
    curl -sL https://git.io/vbsTg | alces_OS=el7 bash
    yum install -y vim ntpdate
    ntpdate 0.pool.ntp.org
    (crontab -l ; echo '* * * * * ntpdate 0.pool.ntp.org') | crontab -
  SHELL
  config.vm.provision "file", source: "~/.cloudware.yml", destination: "~vagrant/.cloudware.yml"
end
