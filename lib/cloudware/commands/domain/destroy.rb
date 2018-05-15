# frozen_string_literal: true

module Cloudware
  module Commands
    module Domain
      class Destroy < Command
        include Concerns::DomainInput

        def run
          d_remove_me = Cloudware::Domain.new
          d_remove_me.name = name

          run_whirly('Checking domain exists') do
            raise("Domain name #{options.name} does not exist") unless d_remove_me.exists?
          end

          run_whirly("Destroying domain #{options.name}") do
            d_remove_me.destroy
          end
        end
      end
    end
  end
end
