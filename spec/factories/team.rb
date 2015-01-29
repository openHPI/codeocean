FactoryGirl.define do
  factory :team do
    internal_users { build_pair :teacher }
    name 'A-Team'
  end
end
