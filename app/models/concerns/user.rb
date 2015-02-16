module User
  extend ActiveSupport::Concern

  ROLES = %w(admin teacher)

  included do
    belongs_to :consumer
    has_many :exercises, as: :user
    has_many :file_types, as: :user
    has_many :submissions, as: :user

    scope :with_submissions, -> { where('id IN (SELECT user_id FROM submissions)') }
  end

  ROLES.each do |role|
    define_method("#{role}?") { self.try(:role) == role }
  end

  def external?
    is_a?(ExternalUser)
  end

  def internal?
    is_a?(InternalUser)
  end

  def to_s
    name
  end
end
