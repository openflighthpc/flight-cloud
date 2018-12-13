
require 'tty-spinner'

module Cloudware
  class Spinner < TTY::Spinner
    def run_with_background_checks(&block)
      results = nil
      run { |_| results = yield }
      results
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
