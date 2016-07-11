require 'active_record'
require 'pg'
require "bunny"
require 'json'
require 'pp'

class Files < ActiveRecord::Base

	establish_connection(
	        :adapter  => "postgresql",
	        :host     => "localhost",
	        :database => "code_ocean_development",
	        :username => "postgres",
	        :password => "postpass"
	)

end

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

total_start = Time.now

index=1


exercise_data = Files.connection.execute("select files.name as file_name, files.role as file_role, file_types.file_extension as file_ext, files.read_only as file_readonly, files.content as file_content from files, file_types where files.context_id=162 and files.context_type='Exercise' and files.file_type_id=file_types.id;")

submissions_data = Files.connection.execute("select distinct on(submissions.user_id, files.name, file_types.file_extension) submissions.user_id as user_id, files.name as file_name, file_types.file_extension as file_ext, files.read_only as file_readonly,files.role as file_role, files.content as file_content from exercises, files, file_types, submissions where exercises.id = 162 and files.file_type_id=file_types.id and submissions.id = files.context_id and submissions.exercise_id=exercises.id and submissions.cause='submit' order by submissions.user_id, files.name, file_types.file_extension, date(submissions.created_at) desc;")

puts "Processing " + submissions_data.count.to_s + " number of submissions..."
submissions_hash = {}

submissions_data.each{|row|
	(submissions_hash[row["user_id"]] ||= []) << [row["file_name"], row["file_ext"], row["file_readonly"], row["file_role"], row["file_content"]]
}
#pp $submissions_hash


submissions_hash.each do |user_id, files|
	exercise_data.each { |row|
		system 'mkdir', '-p', "projects/#{user_id}/src"
		File.open("projects/#{user_id}/src/"+row["file_name"]+row["file_ext"], "w") { |f| f.write(row["file_content"]) }
	}
	files.each do |file|
		#if ["main_file", "user_defined_file", "user_defined_test"].include?(file[3]) then
		system 'mkdir', '-p', "projects/#{user_id}/src"
		File.open("projects/#{user_id}/src/"+file[0]+file[1], "w") { |f| f.write(file[4]) }
	end

	system 'cp', '-R', "lib", "projects/#{user_id}/"
	system 'mkdir', '-p', "projects/#{user_id}/bin"

	make_contents = "
sonar:
	javac -encoding utf8 -d bin -cp \".:./lib/*:$CLASSPATH\" src/*.java
	java -javaagent:./lib/org.jacoco.agent-0.7.6.201602180812-runtime.jar=includes=MyRule54CA,excludes=MySpecificTest,output=file,destfile=./reports/jacoco.exec -cp \".:./bin:./lib/*:$CLASSPATH\" MyTestRunner
	/opt/sonar-scanner-2.6.1/bin/sonar-scanner -Dsonar.projectKey=P#{user_id} -Dsonar.projectName=P#{user_id} -Dsonar.projectVersion=1.0 -Dsonar.sources=./src/ -Dsonar.language=java -Dsonar.sourceEncoding=UTF-8 -Dsonar.jacoco.reportPath=./reports/jacoco.exec -Dsonar.java.binaries=./bin/ -Dsonar.java.test.binaries=./bin/ -Dsonar.java.test.libraries=./lib/*.jar -Dsonar.java.libraries=./lib/*.jar -Dsonar.inclusions=**/MyRule54CA.java,**/MySpecificTest.java -Dsonar.coverage.exclusions=**/MySpecificTest.java

clean:
	rm -rf ./bin/*.class ./reports/*
	touch ./reports/jacoco.exec
"

	File.open("projects/#{user_id}/Makefile", "w") { |f| f.write(make_contents) }

  # start_db_size = Size.connection.execute("SELECT pg_database_size('sonarqube')").first.to_s.scan(/\d/).join('').to_i
	start_time = Time.now
	#puts "startDBsize--------" + start_db_size.to_s

	msg_object = [user_id, start_time, 0]#start_db_size
	message = JSON.dump msg_object
	ch.default_exchange.publish(message, :routing_key => q.name)
	puts "Sent scan request for code: " + user_id

	index+=1
end

conn.close
