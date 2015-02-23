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
    define_method("#{role}?") { try(:role) == role }
  end

  [ExternalUser, InternalUser].each do |klass|
    define_method("#{klass.name.underscore}?") { is_a?(klass) }
  end

  def to_s
    name
  end
end
