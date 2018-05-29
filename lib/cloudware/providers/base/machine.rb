# frozen_string_literal: true

module Cloudware
  module Providers
    module Base
      class Machine < Application
        attr_accessor :name, :type, :flavour, :domain, :role, :priip,
                      :state, :extip, :instance_id, :id, :provider_type,
                      :cluster_index

        delegate :region, :provider, to: :domain

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
