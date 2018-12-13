
require 'tty-spinner'
require 'tty-command'

module Cloudware
  class Spinner < TTY::Spinner
    CHECK_SPIN = 10
    SPIN_DELAY = 0.1

    def initialize(message, **k)
      @tty_spinner = TTY::Spinner.new(message, **k)
      @tty_cmd = TTY::Command.new
    end

    def run(done_message = '', &block)
      results = nil
      thr = Thread.new { results = yield }
      count = 0
      until thr.join(SPIN_DELAY)
        update_foreground_status if count % CHECK_SPIN == 0
        count += 1
        tty_spinner.spin if foreground
      end
      results
    ensure
      tty_spinner.stop(done_message) if foreground
    end

    private

    attr_reader :tty_spinner, :tty_cmd
    attr_accessor :foreground

    def update_foreground_status
      status = `ps -o stat= -p #{Process.pid}`
      self.foreground = /.*\+.*/.match?(status)
    end
  end

  module WithSpinner
    def with_spinner(msg = '', done: '', &block)
      Spinner.new("[:spinner] #{msg}", format: :pipe)
             .run(done, &block)
    end
  end
end
