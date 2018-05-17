
module Cloudware
  module Models
    class Machine < Application
      ATTRIBUTES = [
        :name, :type, :flavour, :domain, :role, :priip, :state, :extip,
        :instance_id, :id
      ]
      DOMAIN_ATTRIBUTES = [:region, :provider]

      def self.delegate_attributes
        ATTRIBUTES.dup.concat(DOMAIN_ATTRIBUTES.dup)
      end

      attr_accessor(*ATTRIBUTES)
      delegate(*DOMAIN_ATTRIBUTES, to: :domain)

      def run_create
        provider_machine.create
      end

      private

      def provider_machine
        Providers.select(provider)::Machine.new(self)
      end
    end
  end
end
