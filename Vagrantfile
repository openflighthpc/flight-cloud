# -*- mode: ruby -*-
# vi: set ft=ruby :

###
# INSTALLATION NOTES w/ VirtualBox
#
# The official "centos/7" box does not come with the drivers for Oracle
# "Virtual Box Guest Additions". They need to be installed from a virtual
# disk
# https://wiki.centos.org/HowTos/Virtualization/VirtualBox/CentOSguest
#
# The above method in-short:
# 1. Installs a bunch of dev tools,
# 2. Downloads: 'VBoxGuestAdditions_<version>.iso'
#    url: http://download.virtualbox.org/virtualbox/
# 3. Mounts the image on the guest VM and installs
#
# => Install Plugin: `vagrant-vbguest`
#    https://github.com/dotless-de/vagrant-vbguest
#
# This vagrant plugin "auto-magically" downloads and installs the iso. YAY
#
# Run:  `vagrant plugin install vagrant-vbguest`
#
# Everything should just work, sort of, BUTTT Vagrant ....
#
# INSTALLATION NOTES w/ Ubuntu
#
# There is a bug in Ubuntu `vagrant 1.8.1` plugin commands
#
# Most of the `plugin` commands end in a "NoMethodError". The issue has been
# identified and will be fixed in version "1.8.2"
#
# In the meantime follow this guide on how to install the patch:
# https://stackoverflow.com/questions/36811863/cant-install-vagrant-plugins-in-ubuntu/36991648#36991648
#

$src_dir = '/tmp/cloudware'
$script = <<SHELL
  # Login as root and change to project dir
  echo 'sudo su -' > /home/vagrant/.bashrc
  echo 'cd #{$src_dir}' >> /root/.bashrc

  # Update system clock
  yum -y -e0 install ntp
  systemctl stop ntpd
  rm -f /etc/localtime
  ln -s /usr/share/zoneinfo/GB /etc/localtime
  ntpdate -s 0.centos.pool.ntp.org
  systemctl start ntpd
  hwclock --systohc

  # Move provider credentials into place
  # (Vagrant does not allow provisioning of files into the root dir)
  mv /home/vagrant/.flightconnector.yml /root/.flightconnector.yml

  # Install helpful packages
  yum install -y vim tree

  # Remove old logs
  rm -rf #{$src_dir}/tmp # Remove the old build logs

  # Install cloudware and add it to the PATH
  bash "#{File.join($src_dir, 'scripts/install')}" "el7"
  echo 'PATH=/opt/cloudware/opt/ruby/bin:$PATH' >> /root/.bashrc
SHELL

Vagrant.configure('2') do |config|
  config.vm.box = 'centos/7'
  config.vm.hostname = 'controller'
  config.vm.synced_folder '.', '/vagrant', disabled: true
  config.vm.synced_folder '.', $src_dir

  # Copies your local flightconnector config into the 'vagrant' user's
  # $HOME directory. This will be picked up by the provisioning script
  # and moved into the 'root' user's $HOME directory. It is not possible
  # to do this in a single step
  config.vm.provision 'file',
                      source: '~/.flightconnector.yml',
                      destination: '~/.flightconnector.yml'

  # Provisions the VM with the above script
  config.vm.provision 'shell', inline: $script
end
