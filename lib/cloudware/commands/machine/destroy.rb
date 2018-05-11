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

          run_whirly('Checking machine exists') do
            raise('Machine does not exist') unless m.exists?
          end

          run_whirly("Destroying #{options.name} in domain #{options.domain}") do
            m.destroy
          end
        end
      end
    end
  end
end
