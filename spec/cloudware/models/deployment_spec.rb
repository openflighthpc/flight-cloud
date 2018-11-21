# frozen_string_literal: true

RSpec.describe Cloudware::Models::Deployment do
  let(:parent_results) { { key1: 'value1', key2: 'value2' } }
  let(:parent) do
    build(:deployment).tap do |model|
      allow(model).to receive(:results).and_return(parent_results)
    end
  end

  let(:child) { build(:deployment, parent: parent) }
end
