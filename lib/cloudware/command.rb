# frozen_string_literal: true

module Cloudware
  class Command
    def initialize(args, options)
      @args = args.freeze
      @options = OpenStruct.new(options.__hash__)
    end

    def run!
      unpack_args
      define_required_options
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

    def combined_requied_options
      [:region, :provider].concat(Array.wrap(required_options))
    end

    def handle_fatal_error(e)
      Cloudware.log.fatal(e.message)
      raise e
    end

    def define_required_options
      combined_requied_options.each do |opt|
        next if options.method_missing(opt)
        options.define_singleton_method(opt) do
          raise InvalidInput, <<-ERROR.squish
            Missing the required --#{opt} input
          ERROR
        end
      end
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
