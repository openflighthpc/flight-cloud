# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure("2") do |config|
  config.vm.box = 'centos/7'
  config.vm.hostname = 'controller'
  config.vm.provision "shell", inline: <<-SHELL
    curl -sL https://git.io/vbsTg | alces_OS=el7 bash
  SHELL
end
