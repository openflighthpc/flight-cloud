
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
end
