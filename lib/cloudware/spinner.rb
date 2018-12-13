
require 'tty-spinner'

module Cloudware
  class Spinner < TTY::Spinner
    def initialize(*a, **k)
      @tty_spinner = TTY::Spinner.new(*a, **k)
    end

    def run(&block)
      results = nil
      thr = Thread.new { results = yield }
      tty_spinner.spin until thr.join(0.1)
      results
    ensure
      tty_spinner.stop
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
