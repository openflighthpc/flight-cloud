
FactoryBot.define do
  models = Cloudware::Models

  factory :domain, class: models::Domain do
    name 'Test-Domain-Name-1'
    provider 'aws'
    region 'eu-west-1'
  end
end
