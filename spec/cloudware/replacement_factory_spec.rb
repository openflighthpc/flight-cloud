# frozen_string_literal: true

#
# =============================================================================
# Copyright (C) 2018 Stephen F. Norledge and Alces Software Ltd
#
# This file is part of Alces Cloudware.
#
# Alces Cloudware is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Alces Cloudware is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Alces Cloudware.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on the Alces Cloudware, please visit:
# https://github.com/alces-software/cloudware
# ==============================================================================
#


require 'cloudware/replacement_factory'

RSpec.describe Cloudware::ReplacementFactory do
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

  subject { described_class.new(context, deployment_name) }

  let(:deployment_name) { 'my-deployment-name' }
  let(:context) { build(:context) }
  let(:key) { :my_key }

  describe '#parse_key_pair' do
    it 'replaces nil values with empty string' do
      expect(subject.parse_key_pair(key, nil)).to eq('')
    end

    it 'returns empty strings' do
      expect(subject.parse_key_pair(key, '')).to eq('')
    end

    it 'returns the value for a regular string' do
      regular = 'I-start-with-a-regular-character'
      expect(subject.parse_key_pair(key, regular)).to eq(regular)
    end

    context 'when referencing a missing deployment' do
      it 'returns an empty string' do
        input = '*missing-deployment'
        expect(subject.parse_key_pair(key, input)).to eq('')
      end
    end

    context 'with a deployment' do
      include_context 'parse-param-deployment'

      context 'with *<deployment-name> inputs' do
        it 'returns the deployment results matching the key' do
          input_value = "*#{deployment_name}"
          expect(subject.parse_key_pair(key, input_value)).to eq(result_string)
        end
      end

      context 'with *<deployment-name>.<other-key>' do
        it 'ignores the input key an uses the other-key instead' do
          input_value = "*#{deployment_name}.#{other_key}"
          expect(subject.parse_key_pair(key, input_value)).to eq(other_result)
        end
      end
    end
  end

  describe '#build' do
    shared_examples 'a default replacement' do
      it 'includes the deployment name' do
        replacements = subject.build(input_string)
        expect(replacements).to include(deployment_name: deployment_name)
      end
    end

    shared_examples 'a literal key value replacement' do
      it 'returns the key value pairing' do
        expect(subject.build(input_string)).to include(key => value)
      end
    end

    shared_examples 'an invalid input' do
      it 'issues an user error' do
        expect { subject.build(value) }.to raise_error(Cloudware::InvalidInput)
      end
    end

    context 'when the string is missing an =' do
      let(:value) { 'i-am-not-a-key-value-pair' }
      it_behaves_like 'an invalid input'
    end

    context 'with a regular key=value string' do
      let(:value) { 'my-value' }
      let(:input_string) { "#{key}=#{value}" }

      it_behaves_like 'a default replacement'
      it_behaves_like 'a literal key value replacement'
    end

    context 'when the value contains a correctly quoted space' do
      let(:value) { 'some string with spaces' }
      let(:input_string) { "#{key}='#{value}'" }

      it_behaves_like 'a default replacement'
      it_behaves_like 'a literal key value replacement'
    end

    context 'with an incorrectly quoted string' do
      let(:value) { '"missing-closing-quote' }
      it_behaves_like 'an invalid input'
    end

    context 'with a deployment' do
      let(:input_string) { "#{key}=*#{deployment_name}" }
      include_context 'parse-param-deployment'

      it_behaves_like 'a default replacement'

      it 'replaces the referenced result' do
        expect(subject.build(input_string)).to include(key => result_string)
      end
    end

    context 'with multi key-pair input string' do
      let(:test_hash) { { key1: 'string1', key2: 'string2' } }
      let(:input_string) do
        test_hash.reduce('') do |memo, (key, value)|
          memo += " #{key}=#{value}"
        end
      end

      it_behaves_like 'a default replacement'

      it 'returns all the key pairs' do
        expect(subject.build(input_string)).to include(**test_hash)
      end
    end

    context 'with an empty string input' do
      let(:input_string) { '' }

      it_behaves_like 'a default replacement'
    end

    context 'wit a nil input' do
      let(:input_string) { nil }

      it_behaves_like 'a default replacement'
    end
  end
end
