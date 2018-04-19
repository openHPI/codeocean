namespace :codeharbor do

  desc 'write displaynames retrieved from the account service as csv into the codeocean database'

  task :export_exercise_collection, [:exercise_collection_id, :push_url, :push_token] => [:environment] do |t, args|

    begin
      ExerciseCollection.find(args.exercise_collection_id).exercises.each do |exercise|
        oauth2Client = OAuth2::Client.new('client_id', 'client_secret', :site => args.push_url)
        token = OAuth2::AccessToken.from_hash(oauth2Client, :access_token => args.push_token)
        xml_generator = Proforma::XmlGenerator.new
        xml_document = xml_generator.generate_xml(exercise)
        token.post(args.push_url, {body: xml_document, headers: {'Content-Type' => 'text/xml'}})
      end
    rescue ActiveRecord::RecordNotFound
      puts "Could not find Exercise Collection with id=#{args.exercise_collection_id}."
    end
  end
end