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
        Rails.logger.debug "Show this message!"
        self.errors.add(:base, "There can only be one default execution environment for any programming language.")
        return false
      end
    end
    return true
  end
end
