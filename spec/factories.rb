
FactoryBot.define do
  models = Cloudware::Models

  factory :domain, class: models::Domain do
    name 'test-domain-name'
  end
end
