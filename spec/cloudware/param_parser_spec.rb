# frozen_string_literal: true

require 'cloudware/param_parser'

RSpec.describe Cloudware::ParamParser do
  shared_context 'parse-param-deployment' do
    let(:result_string) { 'value from deployment' }
    let(:other_key) { :my_super_other_key }
    let(:other_result) { 'I am the other keys result' }
    let(:deployment_results) do
      { key => result_string, other_key => other_result }
    end
    let(:deployment_name) { 'my-deployment' }
    let(:deployment) do
      build(:deployment, name: deployment_name, results: deployment_results)
    end

    before { context.with_deployment(deployment) }
  end

  subject { described_class.new(context) }

  let(:context) { build(:context) }
  let(:key) { :my_key }

  describe '#pair' do
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

    context 'when referencing a missing deployment' do
      it 'returns an empty string' do
        input = '*missing-deployment'
        expect(subject.pair(key, input)).to eq('')
      end
    end

    context 'with a deployment' do
      include_context 'parse-param-deployment'

      context 'with *<deployment-name> inputs' do
        it 'returns the deployment results matching the key' do
          input_value = "*#{deployment_name}"
          expect(subject.pair(key, input_value)).to eq(result_string)
        end
      end

      context 'with *<deployment-name>.<other-key>' do
        it 'ignores the input key an uses the other-key instead' do
          input_value = "*#{deployment_name}.#{other_key}"
          expect(subject.pair(key, input_value)).to eq(other_result)
        end
      end
    end
  end

  describe '#string' do
    context 'when the string is missing an =' do
      it 'issues an user error' do
        str = 'i-am-not-a-key-value-pair'
        expect { subject.string(str) }.to raise_error(Cloudware::InvalidInput)
      end
    end

    context 'with a regular key=value string' do
      let(:value) { 'my-value' }
      let(:input) { "#{key}=#{value}" }

      it 'returns the key value pairing' do
        expect(subject.string(input)).to eq([key, value])
      end
    end

    context 'with a deployment' do
      include_context 'parse-param-deployment'

      it 'replaces the referenced result' do
        str = "#{key}=*#{deployment_name}"
        expect(subject.string(str)).to eq([key, result_string])
      end
    end
  end
end
