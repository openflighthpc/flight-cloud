# frozen_string_literal: true

module Cloudware
  module Providers
    module Base
      class Machine < Application
        ATTRIBUTES = [
          :name, :type, :flavour, :domain, :role, :priip, :state, :extip,
          :instance_id, :id, :provider_type, :cluster_index
        ]
        DOMAIN_ATTRIBUTES = [:region, :provider]

        attr_accessor(*ATTRIBUTES)
        delegate(*DOMAIN_ATTRIBUTES, to: :domain)

        def power_on
          raise NotImplementedError
        end

        def power_off
          raise NotImplementedError
        end

        private

        def run_create
          raise NotImplementedError
        end

        def run_destroy
          raise NotImplementedError
        end
      end
    end
  end
end
