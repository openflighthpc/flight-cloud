
FactoryBot.define do
  models = Cloudware::Models

  factory :domain, class: models::Domain do
    name 'Test-Domain-Name-1'
    provider 'aws'
    region 'eu-west-1'
    networkcidr '10.0.0.0/16'
    prisubnetcidr '10.0.1.0/24'
  end
end
