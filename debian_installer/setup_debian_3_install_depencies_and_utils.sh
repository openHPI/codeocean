if [ ! -f /etc/apt/sources.list.d/nonfree.list ]
then
  echo "Get additional sources for apt-get"
  cd /etc/apt/sources.list.d
  sudo touch nonfree.list
  sudo sh -c 'echo "deb http://http.debian.net/debian stretch main non-free contrib" > nonfree.list'
  sudo sh -c 'echo "deb-src http://http.debian.net/debian stretch main non-free contrib" >> nonfree.list'
  sudo sh -c 'echo "deb http://http.debian.net/debian stretch-updates main contrib non-free" >> nonfree.list'
  sudo sh -c 'echo "deb-src http://http.debian.net/debian stretch-updates main contrib non-free" >> nonfree.list'
  sudo apt-get update
else
  # install utilities
  echo "Additional apt-get sources already added"
fi

# install utilities
echo "Install some utils..."
sudo apt-get install -y --force-yes screen
sudo apt-get install -y --force-yes htop
echo "Done"

# install dependencies
echo "Install some libraries..."
sudo apt-get install -y --force-yes git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev
sudo apt-get install -y --force-yes libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev
sudo apt-get install -y --force-yes python-software-properties libffi-dev
sudo apt-get install -y --force-yes libgdbm-dev libncurses5-dev automake libtool bison libffi-dev
sudo apt-get install -y --force-yes libpq-dev
echo "Done"

# get the clock in sync
echo "Install clock synchronization..."
sudo apt-get install -y --force-yes ntp ntpdate
echo "Done"

echo "Install NodeJS..."
# install nodejs
sudo apt-get install -y --force-yes nodejs
echo "Done"

if ! (ruby -v | grep -q 2.3.3)
then
  # install rvm
  echo "Install RVM..."
  gpg2 --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
  \curl -sSL https://get.rvm.io | bash -s stable --ruby
  source /home/debian/.rvm/scripts/rvm
  echo "Done"
  # install ruby
  echo "Install Ruby 2.3.3..."
  rvm install 2.3.3
  rvm use 2.3.3 --default
  ruby -v
  exec bash
  echo "Done"
else
  echo "RVM and Ruby are already installed"
fi

# install guest additions - required for sharing a folder
echo "Install prerequisites for guest additions..."
sudo apt-get install -y --force-yes dkms build-essential linux-headers-amd64
echo "Done"

echo "Please follow the instructions:"
echo "Insert Guest Additions CD image. VM: Devices=>Insert Guest Additions CD image"
echo "Install Guest Additions"
