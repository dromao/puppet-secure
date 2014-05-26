#!/bin/bash

# Secure Ubuntu Puppet modules install

# Ufw firewall module:
git clone https://github.com/attachmentgenie/puppet-module-ufw.git /etc/puppet/modules/ufw

# Augeas: A configuration file modifier
git clone https://github.com/camptocamp/puppet-augeas.git /etc/puppet/modules/augeas

# Puppet stdlib, required for the file_line function
puppet module install puppetlabs-stdlib

# Fail2Ban
puppet module install netmanagers-fail2ban

# Cron
git clone https://github.com/torrancew/puppet-cron.git /etc/puppet/modules/cron