# frozen_string_literal: true

module Cloudware
  module Providers
    module Base
      class Machine < Application
        attr_accessor :name, :type, :flavour, :domain, :role, :priip,
                      :state, :extip, :instance_id, :id, :cluster_index
        attr_writer :provider_type

        delegate :region, :provider, to: :domain

        def power_on
          raise NotImplementedError
        end

        def power_off
          raise NotImplementedError
        end

        private

        def machine_mappings
          YAML.load_file(File.join(
            Cloudware.config.base_dir,
            "providers/#{provider}/mappings/machine_types.yml"
          ))
        end
        memoize :machine_mappings

        def provider_type
          @provider_type ||= machine_mappings[flavour][type]
        end
      end
    end
  end
end
