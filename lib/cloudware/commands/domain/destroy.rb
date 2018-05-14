# frozen_string_literal: true

module Cloudware
  module Commands
    module Domain
      class Destroy < Command
        def run
          d = Cloudware::Domain.new

          options.name = ask('Domain name: ') if options.name.nil?
          d.name = options.name.to_s

          run_whirly('Checking domain exists') do
            raise("Domain name #{options.name} does not exist") unless d.exists?
          end

          run_whirly("Destroying domain #{options.name}") do
            d.destroy
          end
        end
      end
    end
  end
end
