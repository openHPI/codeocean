# frozen_string_literal: true

namespace :gdpr do
  desc 'Deletes user accounts in accordance with GDPR. ' \
       'Requires a text file with external user IDs (one per line) and ' \
       'the corresponding consumer for deletion. Pass those via ' \
       'TXT=/path/to/file.txt and CONSUMER=Name.'
  task delete_users: :environment do
    text_file_location = ENV.fetch('TXT')
    consumer_name = ENV.fetch('CONSUMER')

    if text_file_location.blank? || consumer_name.blank?
      warn '--------------------------------------'
      warn 'GDPR deletion tool to remove personal user data. USAGE:'
      warn '--------------------------------------'
      warn 'rake gdpr:delete_users TXT=./accounts.txt CONSUMER=openHPI'
      exit 1
    end

    consumer = Consumer.where('lower(name) = ?', consumer_name.downcase).first

    if consumer.blank?
      warn '--------------------------------------'
      warn "ERROR: The consumer '#{consumer_name}' was not found but is mandatory."
      warn '--------------------------------------'
      exit 2
    end

    user_ids = begin
      File.readlines(text_file_location).map(&:strip).compact_blank
    rescue SystemCallError => e
      warn '--------------------------------------'
      warn "ERROR: The file '#{text_file_location}' could not be opened: #{e.message}"
      warn '--------------------------------------'
      exit 3
    end

    unknown_user_ids = []
    errored_user_ids = []
    users_deleted = 0

    user_ids.each do |user_id|
      user = ExternalUser.find_by(external_id: user_id, consumer:)
      if user.blank?
        unknown_user_ids << user_id
        next
      end

      if user.update(name: 'Deleted User', email: nil)
        users_deleted += 1
      else
        errored_user_ids << user_id
      end
    end

    if unknown_user_ids.any?
      warn '--------------------------------------'
      warn 'WARNING: Some user IDs were not found:'
      warn '--------------------------------------'
      unknown_user_ids.each do |user_id|
        warn user_id
      end
    end

    if errored_user_ids.any?
      warn '--------------------------------------'
      warn 'WARNING: Some user IDs were found but were not processed successfully:'
      warn '--------------------------------------'
      errored_user_ids.each do |user_id|
        warn user_id
      end
    end

    puts '--------------------------------------'
    puts "SUCCESS: #{users_deleted} user(s) deleted."
    puts '--------------------------------------'
  end
end
