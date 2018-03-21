class ProgrammingLanguage < ActiveRecord::Base
  belongs_to :execution_environment
  validates :name, uniqueness: {scope: [:version, :default], message: "There can only be one default programming language."}, if: :default

  def name_with_version
    "#{name} #{version}"
  end
end
