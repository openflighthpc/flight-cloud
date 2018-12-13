
require 'tty-spinner'

module Cloudware
  class Spinner < TTY::Spinner
    def initialize(*a, **k)
      @tty_spinner = TTY::Spinner.new(*a, **k)
    end

    def run(&block)
      results = nil
      tty_spinner.run { |_| results = yield }
      results
    end

    private

    attr_reader :tty_spinner
  end

  module WithSpinner
    def with_spinner(msg = '', &block)
      spinner = Spinner.new("[:spinner] #{msg}", format: :shark)
      results = nil
      spinner.run_with_background_checks(&block)
      results
    end
  end
end
