
# frozen_string_literal: true

FactoryBot.define do
  models = Cloudware::Models

  factory :deployment, class: models::Deployment do
    name 'test-deployment'
    template_name 'test-template'
    results {}
  end
end
