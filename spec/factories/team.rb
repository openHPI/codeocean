FactoryGirl.define do
  factory :team do
    internal_users { build_pair :teacher }
    name 'The A-Team'
  end
end
