# create, migrate, and seed database tables
cd /home/debian/codeocean_host
export RAILS_ENV=development

echo "load, seed, migrate"
rake db:schema:load
rake db:seed
rake db:migrate