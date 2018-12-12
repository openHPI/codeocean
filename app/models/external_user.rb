class ExternalUser < ApplicationRecord
  include User

  validates :consumer_id, presence: true
  validates :external_id, presence: true

  def name
    # Internal name, shown to teachers and administrators
    pseudo_name
  end

  def displayname
    # External name, shown to the user itself and other users, e.g. on RfCs
    pseudo_name
  end

  def real_name
    # Name attribute of the object as persistet in the database
    self[:name]
  end

  def pseudo_name
    if real_name.blank?
      "User " + id.to_s
    else
      real_name
    end
  end
  private :pseudo_name

end
