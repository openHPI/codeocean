
# Distributed CodeOcean on CoreOS

This directory contains images and scripts we used in our proof of concept of a distributed CodeOcean setup.


## images/

There are 3 images in this container.

 * CodeOcean (codeocean)
 * PotsgreSQL (postgres)
 * Python Environment (ubuntu-python)


## fleetctl-units.py

This script is used to retrieve all containers launched with fleet within the cluster.
CodeOcean calls the script at `docker_client.rb:115`. Depending on the location of the script on the file system that line has to be adjusted.
It would also be possible to incorporate the functionality into CodeOcean.


