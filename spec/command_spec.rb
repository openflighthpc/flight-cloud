
require 'ostruct'

module Cloudware
  module Commands
    class TestCommand < Command
    def run; end
    end
  end
end

RSpec.describe Cloudware::Command do
  subject { Cloudware::Commands::TestCommand.new(args, options) }
  let(:args) { [] }
  let(:options) { OpenStruct.new() }

  it 'does nothing with blank arguments' do
    expect { subject.run! }.not_to raise_error
  end

  describe '#required_options' do
    let(:required) { [:required_option1, :required_option2] }
    before do
      allow(subject).to receive(:required_options).and_return(required)
    end

    context 'with the required options' do
      let(:options) do
        required.each_with_object(OpenStruct.new) do |opt, accum|
          accum[opt] = 'filled'
        end
      end

      it 'does not error' do
        expect { subject.run! }.not_to raise_error
      end
    end
  end
end
