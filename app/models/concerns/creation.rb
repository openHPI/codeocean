module Creation
  extend ActiveSupport::Concern

  included do
    belongs_to :user, polymorphic: true
    alias_method :author, :user
    alias_method :creator, :user

    validates :user_id, presence: true
    validates :user_type, presence: true
  end
end
