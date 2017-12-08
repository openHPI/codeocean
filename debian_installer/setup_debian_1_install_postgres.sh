# update apt-get
echo "Update apt-get..."
sudo apt-get update
# upgrade all packages
echo "Upgrade packages..."
sudo apt-get upgrade

#install postgres
if [ ! -f /etc/apt/sources.list.d/pgdg.list ]
then
  echo "Add Postgres sources..."
  cd /etc/apt/sources.list.d
  sudo touch pgdg.list
  sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ stretch-pgdg main" > pgdg.list'
  sudo wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
  sudo apt-get update
  echo "Done"
else
  echo "Postgres sources already added"
fi

sudo apt-get -y --force-yes install postgresql-9.5

# drop postgres access control
if [ -f /etc/postgresql/9.5/main/pg_hba.conf ]
then
  if ! sudo -u postgres grep -q CodeOcean /etc/postgresql/9.5/main/pg_hba.conf
  then
    echo "Drop Postgres access control..."
    sudo -u postgres sh -c 'cat >/etc/postgresql/9.5/main/pg_hba.conf <<EOF
#CodeOcean: drop access control
local all all trust
host  all all 127.0.0.1/32 trust
host  all all ::1/128 trust
EOF'
    echo "Done"
    echo "Restart Postgres..."
    echo sudo service postgresql restart
    echo "Done"
  else
    echo "Postgres access control already dropped"
  fi
else
    echo "Postgres installation failed"
fi

# create development database
# TODO: extract databasename to variable
if ! (sudo -u postgres psql -l | grep -q codeocean-development)
then
  echo "Create database codeocean-development..."
  sudo -u postgres createdb codeocean-development || true
  sudo -u postgres psql -d codeocean-development -U postgres -c "CREATE USER root;"
  sudo -u postgres psql -d codeocean-development -U postgres -c 'GRANT ALL PRIVILEGES ON DATABASE "codeocean-development" to root';
  sudo -u postgres psql -d codeocean-development -U postgres -c "CREATE USER debian;"
  sudo -u postgres psql -d codeocean-development -U postgres -c 'GRANT ALL PRIVILEGES ON DATABASE "codeocean-development" to debian';
  sudo -u postgres psql -d codeocean-development -U postgres -c "CREATE USER codeocean;"
  sudo -u postgres psql -d codeocean-development -U postgres -c 'GRANT ALL PRIVILEGES ON DATABASE "codeocean-development" to codeocean';
  sudo -u postgres psql -d codeocean-development -U postgres -c 'ALTER DATABASE "codeocean-development" OWNER TO codeocean';
  sudo -u postgres psql -d codeocean-development -U postgres -c 'ALTER USER "codeocean" CREATEDB';
  echo "Done"
else
  echo "Database codeocean-development already exists"
fi

# TODO: create test database
