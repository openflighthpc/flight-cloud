# -*- mode: ruby -*-
# vi: set ft=ruby :

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
  config.vm.box = 'hfm4/centos7'
  config.vm.hostname = 'controller'
  config.vm.synced_folder '.', '/vagrant', disabled: true
  config.vm.synced_folder '.', $src_dir
  config.vm.provision 'file',
                      source: '~/.flightconnector.yml',
                      destination: '~/.flightconnector.yml'
  config.vm.provision 'shell', inline: $script
end
