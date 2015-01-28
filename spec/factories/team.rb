FactoryGirl.define do
  factory :team do
    internal_users { build_list :teacher, 10 }
    name 'A-Team'
  end
end
