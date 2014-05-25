puppet-secure
=============

Repository aimed at providing puppet manifests to aid the deployment of commonly used network services and operating systems, with a secure configuration in mind. 


How to get started:

1. Install puppet-common package: apt-get install puppet-common
2. Install git (might not be required): apt-get install git
3. Run the dependencies script for the desired service
4. Run: puppet apply $service.pp


NOTE: The code provided should not be used on production environments without prior testing. So far, little testing has been done, and only on Ubuntu Server 14.04 LTS.

This code was wrote for a master's course project by me and Anastasios Poulidis (poulidae@gmail.com).

Contributions are very welcome!
