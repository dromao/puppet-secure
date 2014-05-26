#!/bin/bash

#Puppet original manifest
sudo apt-get install git -y

cd /etc/puppet/modules

sudo git clone https://github.com/arioch/puppet-proftpd.git

sudo mv puppet-proftpd proftpd

#Concat depenedencie
puppet module install puppetlabs-concat
