# frozen_string_literal: true

module Cloudware
  class Command
    extend Memoist

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
      handle_fatal_error(e)
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

    def handle_fatal_error(e)
      Cloudware.log.fatal(e.message)
      raise e
    end

    def run_whirly(status)
      update_status = proc { |s| Whirly.status = s.bold }
      been_ran = false
      result = nil
      Whirly.start do
        been_ran = true
        update_status.call(status)
        Whirly.stop if options.debug
        result = yield update_status if block_given?
      end
      been_ran ? result : (yield update_status if block_given?)
    end
  end
end
