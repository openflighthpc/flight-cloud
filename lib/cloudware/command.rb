# frozen_string_literal: true

module Cloudware
  class Command
    def initialize(input_args, options)
      @input_args = input_args.freeze
      @options = options
    end

    def run!
      unpack_args(input_args.dup)
      run
    rescue Exception => e
      handle_fatal_error(e)
    end

    def unpack_args(args); end

    def run
      raise NotImplementedError
    end

    private

    attr_reader :input_args, :options

    def handle_fatal_error(e)
      Cloudware.log.fatal(e.message)
      raise e
    end
  end
end
