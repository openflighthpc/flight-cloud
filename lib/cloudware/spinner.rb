
require 'tty-spinner'

module Cloudware
  class Spinner < TTY::Spinner
    CHECK_SPIN = 10
    SPIN_DELAY = 0.1

    def initialize(*a, **k)
      @tty_spinner = TTY::Spinner.new(*a, **k)
    end

    def run(&block)
      results = nil
      thr = Thread.new { results = yield }
      count = 0
      until thr.join(SPIN_DELAY)
        update_background_status if count % CHECK_SPIN == 0
        count += 1
        tty_spinner.spin
      end
      results
    end

    private

    attr_reader :tty_spinner

    def update_background_status
      puts 'updating'
    end
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
