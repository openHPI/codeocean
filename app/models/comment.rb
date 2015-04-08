class Comment < ActiveRecord::Base
  # inherit the creation module: encapsulates that this is a polymorphic user, offers some aliases and makes sure that all necessary attributes are set.
  include Creation

  belongs_to :file, class: CodeOcean::File
end
