# frozen_string_literal: true

namespace :user do
  require 'csv'

  desc 'write displaynames retrieved from the account service as csv into the codeocean database'

  task :write_displaynames, [:file_path_read] => [:environment] do |_t, args|
    csv_input = CSV.read(args[:file_path_read], headers: true)

    csv_input.each do |row|
      user = ExternalUser.find_by(external_id: row[0])
      puts "Change name from   #{user.name} to #{row[1]}"
      user.update(name: row[1])
    end
  end
end
