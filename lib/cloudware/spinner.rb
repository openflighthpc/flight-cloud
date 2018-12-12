
require 'tty-spinner'

module Cloudware
  module Spinner
    def with_spinner(msg = '', &block)
      spinner = TTY::Spinner.new("[:spinner] #{msg}", format: :shark)
      results = nil
      spinner.run { |_| results = yield }
      results
    end
  end
end
