
module Cloudware
  module Providers
    class Provider
      def initialize(domain_model)
        @domain_model = domain_model
      end

      private

      attr_reader :domain_model

      delegate(*Models::Domain::ATTRIBUTES, to: :domain_model)

    end
  end
end
