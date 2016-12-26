############# codeocean install ###########################
cd /home/debian/codeocean_host

#install rails and bundler
echo "Install Rails..."
gem install rails
echo "Done"
echo "Install Bundler..."
gem install bundler
echo "Done"

# install required gems
bundle install

# copy config files
for f in action_mailer.yml database.yml secrets.yml sendmail.yml smtp.yml code_ocean.yml
do
  if [ ! -f config/$f ]
  then
    cp config/$f.example config/$f
  fi
done

# Manual Task:
# if necessary adjust db config
echo "Check if settings in database.yml correspond with your database setup."

cat /home/debian/codeocean_host/config/database.yml