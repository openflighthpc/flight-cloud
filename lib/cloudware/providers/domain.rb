# frozen_string_literal: true

module Cloudware
  module Providers
    class Domain
      class << self
        def by_region(_r)
          raise NotImplementedError
        end
      end

      def initialize(domain_model)
        @domain_model = domain_model
      end

      private

      attr_reader :domain_model

      delegate(*Models::Domain::ATTRIBUTES, to: :domain_model)
    end
  end
end
