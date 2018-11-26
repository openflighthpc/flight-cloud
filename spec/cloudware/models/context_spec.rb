# frozen_string_literal: true
require 'models/context'

RSpec.describe Cloudware::Models::Context do
  subject do
    described_class.new.tap do |context|
      allow(context).to receive(:deployments).and_return(deployments)
    end
  end

  context 'with a single deployment' do
    let(:results) { { key: 'value' } }
    let(:deployment) { build(:deployment, results: results) }
    let(:deployments) { [deployment] }

    describe '#results' do
      it "returns the deployment's results" do
        expect(subject.results).to eq(deployments.first.results)
      end
    end
  end
end
