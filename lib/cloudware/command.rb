# frozen_string_literal: true

module Cloudware
  class Command
    def initialize(args, options)
      @args = args.freeze
      @options = options
    end

    def run!
      unpack_args
      enforce_required_options
      run
    rescue Exception => e
      handle_fatal_error(e)
    end

    def unpack_args; end
    def required_options; end

    def run
      raise NotImplementedError
    end

    private

    attr_reader :args, :options

    def handle_fatal_error(e)
      Cloudware.log.fatal(e.message)
      raise e
    end

    def enforce_required_options
    end

    def run_whirly(status)
      update_status = proc { |s| Whirly.status = s.bold }
      Whirly.start do
        update_status.call(status)
        yield update_status if block_given?
      end
    end
  end
end
