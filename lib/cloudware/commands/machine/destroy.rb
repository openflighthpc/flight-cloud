# frozen_string_literal: true

module Cloudware
  module Commands
    module Machine
      class Destroy < Command
        def run
          m = Cloudware::Machine.new

          options.name = ask('Machine name: ') if options.name.nil?
          m.name = options.name.to_s

          options.domain = ask('Domain identifier: ') if options.domain.nil?
          m.domain = options.domain.to_s

          Whirly.start status: 'Checking machine exists'
          raise('Machine does not exist') unless m.exists?
          Whirly.stop

          Whirly.start status: "Destroying #{options.name} in domain #{options.domain}"
          m.destroy
          Whirly.stop
        end
      end
    end
  end
end
