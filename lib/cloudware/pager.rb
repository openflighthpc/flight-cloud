# frozen_string_literal: true

require 'tty/pager'

module Cloudware
  module Pager
    def pager_puts(text)
      if $stdout.isatty
        TTY::Pager.new.page(text)
      else
        puts text
      end
    end
  end
end
