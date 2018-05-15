# frozen_string_literal: true

module Cloudware
  module Commands
    module Domain
      class Destroy < Command
        include Concerns::DomainInput

        def run
          d_remove_me = Cloudware::Domain.new
          d_remove_me.name = name

          run_whirly('Checking domain exists') { domain }
          run_whirly("Destroying domain #{options.name}") do
            d_remove_me.destroy
          end
        end

        private

        def domain
          model = domains_in_region.find { |d| d.name == name }
          return model unless model.nil?
          raise InvalidInput, "Domain name '#{name}' does not exist"
        end

        def domains_in_region
          Providers::Domains.by_provider(options.provider)
                            .by_region(options.region)
        end
      end
    end
  end
end
