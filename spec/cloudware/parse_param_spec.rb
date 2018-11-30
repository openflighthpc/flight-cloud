# frozen_string_literal: true

require 'parse_param'

RSpec.describe Cloudware::ParseParam do
  subject { described_class.new(context) }
  let(:context) { build(:context) }

  describe '#pair' do
    let(:key) { :my_key }

    it 'replaces nil values with empty string' do
      expect(subject.pair(key, nil)).to eq('')
    end

    it 'returns empty strings' do
      expect(subject.pair(key, '')).to eq('')
    end

    it 'returns the value for a regular string' do
      regular = 'I-start-with-a-regular-character'
      expect(subject.pair(key, regular)).to eq(regular)
    end

    context 'with a deployment' do
      let(:result_string) { 'value from deployment' }
      let(:deployment_results) { { key => result_string } }
      let(:deployment_name) { 'my-deployment' }
      let(:deployment) do
        build(:deployment, name: deployment_name, results: deployment_results)
      end

      before { context.with_deployment(deployment) }

      context 'with *<deployment-name> inputs' do
        it 'returns the deployment results matching the key' do
          input_value = "*#{deployment_name}"
          expect(subject.pair(key, input_value)).to eq(result_string)
        end
      end
    end
  end
end
