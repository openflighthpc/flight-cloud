
module Cloudware
  module Models
    class Machine < Application
      ATTRIBUTES = [:name, :type, :flavour, :domain, :role, :priip]
      DOMAIN_ATTRIBUTES = [:region, :provider]

      def self.delegate_attributes
        ATTRIBUTES.dup.concat(DOMAIN_ATTRIBUTES.dup)
      end

      attr_accessor(*ATTRIBUTES)
      delegate(*DOMAIN_ATTRIBUTES, to: :domain)

      def run_create
      end

      private

      def provider_module
        Providers.select(provider)
      end
    end
  end
end
