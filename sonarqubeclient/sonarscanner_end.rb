require 'active_record'
require 'pg'
require 'csv'
require "bunny"
require 'json'
require 'timeout'

# class Size < ActiveRecord::Base
#
#   establish_connection(
#       :adapter  => "postgresql",
#       :host     => "10.210.0.56",
#       :username => "sonarqube",
#       :password => "hairuuzeekae7Aem",
#       :database => "sonarqube"
#   )
#
# end

conn = Bunny.new
conn.start

ch   = conn.create_channel
q    = ch.queue("sourcecodes")

# index=1

# CSV.open("prelim_analysis_CA.csv", "wb") do |csv|

	puts "Waiting for messages in #{q.name}. To exit press CTRL+C"
	q.subscribe(:block => true) do |delivery_info, properties, body|
		body_object = JSON.load body
		puts "Scanning: "+ body_object[0]

    # $start_db_size = Size.connection.execute("SELECT pg_database_size('sonarqube')").first.to_s.scan(/\d/).join('').to_i
		$start_time = Time.now

		begin
			Timeout::timeout(60) {
				system("make -C projects/#{body_object[0]} sonar")
			}
		rescue Timeout::Error
			STDERR.puts "The code submitted by user_id:#{body_object[0]} times out!!!"
		end


    # $finish_time = Time.now
    # $finish_db_size = Size.connection.execute("SELECT pg_database_size('sonarqube')").first.to_s.scan(/\d/).join('').to_i

		# diff_time = $finish_time-$start_time
#     turn_around_time = $finish_time - body_object[1].to_i
#     diff_db_size = $finish_db_size - $start_db_size
#     turn_around_space = $finish_db_size - body_object[2].to_i
#     csv << [index.to_s, body_object[0].to_s, turn_around_time.to_s, turn_around_space.to_s, diff_time.to_s, diff_db_size.to_s]

    # index+=1
	end

  # starttime_dbsize = Time.now
  # final_db_size = Size.connection.execute("SELECT pg_database_size('sonarqube')").first.to_s.scan(/\d/).join('').to_i
  # endtime_dbsize = Time.now

  # dbsize_time_diff = endtime_dbsize - starttime_dbsize

  # total_finish = Time.now
  # total_diff = total_finish - total_start.to_i
  # csv << ["final", total_diff.to_i.to_s, final_db_size.to_s, dbsize_time_diff.to_s]

# end
