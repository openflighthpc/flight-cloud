
# frozen_string_literal: true

module Cloudware
  module Providers
    module AZURE
      class Domains < Base::Domains
        class Builder
          def initialize(region)
            @region ||= region
          end

          def domains
            raise NotImplementedError
          end

          private

          attr_reader :region
        end

        class << self
          private

          def domain_models_by_region(region)
            Builder.new(region).domains
          end
        end
      end
    end
  end
end
