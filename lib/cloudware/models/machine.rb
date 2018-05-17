
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

      private

      def run_create
        provider_machine.create
      end

      def run_destroy
        provider_machine.destroy
      end

      def provider_machine
        Providers.select(provider)::Machine.new(self)
      end
    end
  end
end
