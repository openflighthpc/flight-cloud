# frozen_string_literal: true
require 'models/context'

RSpec.describe Cloudware::Models::Context do
  subject do
    described_class.new.tap do |context|
      deployments.each { |d| context.add_deployment(d) }
    end
  end

  context 'with a single deployment' do
    let(:results) { { single_key: 'value' } }
    let(:deployment) { build(:deployment, results: results) }
    let(:deployments) { [deployment] }

    describe '#results' do
      it "returns the deployment's results" do
        expect(subject.results).to eq(deployments.first.results)
      end
    end

    describe '#save' do
      it 'saves the context so it can be reloaded' do
        subject.save
        new_context = described_class.new
        expect(new_context.results).to eq(subject.results)
      end
    end
  end

  context 'with multiple deployments' do
    let(:initial_results) { { key: 'value', replaced_key: 'wrong' } }
    let(:final_results) { { replaced_key: 'correct' } }
    let(:merged_results) { initial_results.merge(final_results) }

    let(:initial_deployment) { build(:deployment, results: initial_results) }
    let(:final_deployment) { build(:deployment, results: final_results) }
    let(:deployments) { [initial_deployment, final_deployment] }

    describe '#results' do
      it 'replaces the earlier results with the latter' do
        expect(subject.results).to eq(merged_results)
      end
    end
  end
end
