class ProgrammingLanguagesJoin < ActiveRecord::Base
  validates :programming_language, uniqueness: {scope: [:execution_environment, :default], message: "can only have one default execution environment"}, if: :default
  belongs_to :execution_environment
  belongs_to :programming_language
end
