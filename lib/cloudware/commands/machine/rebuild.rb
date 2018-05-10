# frozen_string_literal: true

module Cloudware
  module Commands
    module Machine
      class Rebuild < Command
        def run
          machine = Cloudware::Machine.new
          options.name = ask('Machine name: ') if options.name.nil?
          machine.name = options.name.to_s

          options.domain = ask('Domain identifier: ') if options.domain.nil?
          machine.domain = options.domain.to_s

          Whirly.start status: "Recreating machine #{options.name}"
          machine.rebuild
          Whirly.stop
        end
      end
    end
  end
end
