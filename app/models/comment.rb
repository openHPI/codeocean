class Comment < ActiveRecord::Base
  # inherit the creation module: encapsulates that this is a polymorphic user, offers some aliases and makes sure that all necessary attributes are set.
  include Creation
  attr_accessor :username

  belongs_to :file, class: CodeOcean::File
  belongs_to :user, polymorphic: true
end
