echo "Mount Shared Folder..."
mkdir /home/debian/codeocean_host
sudo mount -t vboxsf -o rw,uid=1000,gid=1000 codeocean /home/debian/codeocean_host

# Enable automount during startup
sudo sh -c 'echo "sudo mount -t vboxsf -o rw,uid=1000,gid=1000 codeocean /home/debian/codeocean_host" >> /home/debian/.bashrc '
echo "Done"