
# frozen_string_literal: true

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
  let(:options) { Commander::Command::Options.new }

  it 'does nothing with blank arguments' do
    expect { subject.run! }.not_to raise_error
  end

  describe '#required_options' do
    let(:required) { [:required_option1, :required_option2] }

    before do
      allow(subject).to receive(:required_options).and_return(required)
    end

    context 'with the required options' do
      before do
        required.each_with_object(options) do |opt, accum|
          accum.default(opt.to_sym => 'filled')
        end
      end

      it 'does not error' do
        expect { subject.run! }.not_to raise_error
      end
    end

    context 'with the options missing' do
      it 'does not error if the option is not used' do
        expect do
          subject.run!
        end.not_to raise_error
      end

      it 'raise an error if the option is used' do
        expect do
          subject.instance_exec(required.first) do |required_option|
            run!
            options.send(required_option)
          end
        end.to raise_error(Cloudware::InvalidInput, /#{required.first}/)
      end
    end
  end
end
