class ProgrammingLanguage < ActiveRecord::Base
  has_many :progamming_languages_joins
  has_many :execution_environments, through: :progamming_languages_joins

  def name_with_version
    "#{name} #{version}"
  end

  def check_default(default)
    if default == "true"
      default_entry = ProgrammingLanguagesJoin.find_by(programming_language: self, default: true)
      if default_entry
        self.errors.add(:base, I18n.t('activerecord.errors.models.programming_languages_join.only_one_default_execution_environment'))
        return false
      end
    end
    return true
  end
end
