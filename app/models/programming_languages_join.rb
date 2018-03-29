class ProgrammingLanguagesJoin < ActiveRecord::Base
  validates :programming_language, uniqueness: {scope: [:execution_environment, :default], message: I18n.t('activerecord.errors.models.programming_languages_join.default_programming_language_validation')}, if: :default
  belongs_to :execution_environment
  belongs_to :programming_language
  accepts_nested_attributes_for :programming_language
end
