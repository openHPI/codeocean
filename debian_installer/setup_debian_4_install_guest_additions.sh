# Mount Guest Additions and run the installer
echo "Mount Guest Additions and run the installer..."
sudo mount /dev/sr0 /media/cdrom
cd /media/cdrom
sudo sh ./VBoxLinuxAdditions.run
echo "Done"
echo "Please follow the instructions:"
echo "Create Shared Folder. VM: Devices=>VM: Devices=>Shared Folders=>Shared Folders Settings"
echo "Name: codeocean, Path: path to your local codeocaen repository on the host machine."

