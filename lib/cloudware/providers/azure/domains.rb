
# frozen_string_literal: true

module Cloudware
  module Providers
    module AZURE
      class Domains < Base::Domains
        class << self
          private

          include Helpers::Client

          def domain_models_by_region(region)
            client.resource.resource_groups.list.select do |rg|
              rg.location == region
            end
          end
        end
      end
    end
  end
end
