class ProgrammingLanguagePolicy < AdminOrAuthorPolicy
  [:create?, :versions?].each do |action|
    define_method(action) { admin? || teacher? }
  end
end