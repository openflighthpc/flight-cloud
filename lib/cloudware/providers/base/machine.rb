# frozen_string_literal: true

module Cloudware
  module Providers
    module Base
      class Machine < Application
        attr_accessor :name, :type, :flavour, :domain, :role, :priip,
                      :extip, :instance_id, :id, :cluster_index
        attr_writer :provider_type

        delegate :region, :provider, to: :domain

        before_create :assign_machine_id

        def power_on
          raise NotImplementedError
        end

        def power_off
          raise NotImplementedError
        end

        def provider_type
          @provider_type ||= machine_mappings[flavour][type]
        end

        private

        def assign_machine_id
          self.id = SecureRandom.uuid unless id
        end

        def machine_mappings
          YAML.load_file(File.join(
            Cloudware.config.base_dir,
            "providers/#{provider}/mappings/machine_types.yml"
          ))
        end
        memoize :machine_mappings

        # Base deploy parameters that all inherited classes should use
        def deployment_parameters
          {
            cloudwareDomain: name,
            cloudwareId: id,
            vmName: name,
            vmType: provider_type,
            priIp: priip,
            vmFlavour: flavour,
          }
        end
      end
    end
  end
end
