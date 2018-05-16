# frozen_string_literal: true

module Cloudware
  module Providers
    module Base
      class Domain
        def initialize(domain_model)
          @domain_model = domain_model
        end

        def create
          raise NotImplementedError
        end

        def destroy
          raise NotImplementedError
        end

        private

        attr_reader :domain_model

        delegate(*Models::Domain::ATTRIBUTES, to: :domain_model)
      end
    end
  end
end
