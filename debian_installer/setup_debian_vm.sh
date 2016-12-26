# Prerequisites:
# 1 Download Debian iso image. http://cdimage.debian.org/debian-cd/8.6.0/amd64/iso-cd/debian-8.6.0-amd64-netinst.iso
# 2 Create Debian VM in VirtualBox:
#    - without GUI
#    - without webserver (we do not want an apache2 but an nginx server)
#    - with ssh ()
# 2 Create 2 users 
#    - debian/debian
#    - root/root

# Manual preparation:
# Login as root
su

# install sudo
apt-get install -y sudo

# add user debian to sudoers and enable this user to sudo without password (do not do this on a production machine)
# or change the line after finishing the installation
cd /etc/sudoers.d
touch debian
echo "debian ALL=(ALL) NOPASSWD:ALL" >> debian
# echo "debian ALL=(ALL:ALL) ALL" >> debian # production systems
# return to no-root user again
exit

# Running the following directly on the VM command line is inconvenient
# Therefore enable login via ssh from Host

# The best way to login to a guest Linux VirtualBox VM is port forwarding. 
# By default, you should have one interface already which is using NAT. 
# Then go to the Network settings and click the Port Forwarding button. Add a new Rule:

# Protocol TCP Host port 3022, guest port 22, name ssh, other left blank.
# That's all! Please be sure you don't forget to install an SSH server:

# To SSH into the guest VM, write:
# ssh -p 3022 user@127.0.0.1
# http://stackoverflow.com/questions/5906441/how-to-ssh-to-a-virtualbox-guest-externally-through-a-host
#=======================================================================================================

# Install postgres 
# run script:
debian_installer/setup_debian_1_install_postgres.sh

# Install docker
# run script:
debian_installer/setup_debian_2_install_docker.sh

# Install dependencies, utils, rvm, ruby, node
# run script:
debian_installer/setup_debian_3_install_depencies_and_utils.sh

##################################local installation on VirtualBox only##################
# Before running the next script, the Guest Additions CD image needs to be inserted via VBox GUI
# Devices=>Insert Guest Additions CD image"
# When that is done run the next script
debian_installer/setup_debian_4_install_guest_additions.sh

# Before running the next script, a Shared Folder has to be created via VBox GUI
# Devices=>Shared Folders=>Shared Folders Settings
# Folder Name: codeocean, Folder Path: path to your local codeocean repository on the host machine.
# Automount, Make Permanent
# When that is done run the next script
debian_installer/setup_debian_5_mount_shared_folder.sh
##################################local installation on VirtualBox only##################

# Install rails and bundler
# run script:
debian_installer/setup_debian_6_setup_codeocean.sh

# Create, seed, and migrate database tables
# run script:
debian_installer/setup_debian_7_create_tables.sh

# Add Port Forwarding for Rails server:

# Protocol TCP Host port 3030, guest port 3000, name CodeOcean, other left blank.
# That's all! 
# Start Puma server on VM
# rails s -p 3000 

# To connect to Ruby app use 
#http://127.0.0.1:3030


#TODO production: 
# require passwd for sudo again.
# cd /etc/sudoers.d
# echo "debian ALL=(ALL:ALL) ALL" > debian

#TODO production: Install nginx
# install nginx
# echo "Install NGINX..."
# sudo apt-get install -y --force-yes nginx
# echo "Done"














