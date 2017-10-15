class Comment < ActiveRecord::Base
  # inherit the creation module: encapsulates that this is a polymorphic user, offers some aliases and makes sure that all necessary attributes are set.
  include Creation
  attr_accessor :username, :date, :updated, :editable

  belongs_to :file, class_name: 'CodeOcean::File'
  belongs_to :user, polymorphic: true
end
