
module Cloudware
  module Providers
    module Domains
      class Domain
        def initialize(domain_model)
          @domain_model = domain_model
        end

        private

        attr_reader :domain_model

        delegate(*Models::Domain::ATTRIBUTES, to: :domain_model)
      end
    end
  end
end
