# frozen_string_literal: true

module Cloudware
  class Command
    def initialize(args, options)
      @args = args.freeze
      @options = options
    end

    def run!
      unpack_args
      run
    rescue Exception => e
      handle_fatal_error(e)
    end

    def unpack_args; end

    def run
      raise NotImplementedError
    end

    private

    attr_reader :args, :options

    def handle_fatal_error(e)
      Cloudware.log.fatal(e.message)
      raise e
    end
  end
end
