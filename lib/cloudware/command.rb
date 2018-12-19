# frozen_string_literal: true

require 'spinner'

module Cloudware
  class Command
    extend Memoist
    include WithSpinner

    def initialize(argv, options)
      @argv = argv.freeze
      @options = OpenStruct.new(options.__hash__)
      if options.debug
        Bundler.setup(:default, :development)
        require 'pry'
      end
    end

    def run!
      run
    rescue Exception => e
      Cloudware.log.fatal(e.message)
      raise e
    end

    def run
      raise NotImplementedError
    end

    def context
      Models::Context.new(region: options.region)
    end
    memoize :context

    private

    attr_reader :argv, :options
  end
end
