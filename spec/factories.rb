
# frozen_string_literal: true

FactoryBot.define do
  aws = Cloudware::Providers::AWS

  factory :aws_domain, class: aws::Domain do
    name 'Test-Domain-Name-1'
    region 'eu-west-1'
    networkcidr '10.0.0.0/16'
    prisubnetcidr '10.0.1.0/24'
  end
end
