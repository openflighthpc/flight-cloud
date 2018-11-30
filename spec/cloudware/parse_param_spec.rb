# frozen_string_literal: true

require 'parse_param'

RSpec.describe Cloudware::ParseParam do
  subject { described_class.new }

  describe '#pair' do
    let(:key) { :my_key }

    it 'replaces nil values with empty string' do
      expect(subject.pair(key, nil)).to eq('')
    end

    it 'returns the value for a regular string' do
      regular = 'I-start-with-a-regular-character'
      expect(subject.pair(key, regular)).to eq(regular)
    end
  end
end
