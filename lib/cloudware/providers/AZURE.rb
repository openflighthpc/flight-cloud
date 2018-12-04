# frozen_string_literal: true

require 'providers/base'

module Cloudware
  module Providers
    module AZURE
      class Machine < Base::Machine
      end

      class Client < Base::Client
        def deploy(name, template)
          group = create_resource_group(name)
          deployment = build_deployment(template)
          resource_client.deployments
                         .create_or_update(group.name, name, deployment)
        end

        private

        def create_resource_group(name)
          rg_name = "#{name}-rg"
          group = resource_client.model_classes.resource_group.new
          group.location = region
          resource_client.resource_groups.create_or_update(rg_name, group)
        end

        def build_deployment(template)
          resource_client.model_classes.deployment.new.tap do |d|
            d.properties = resource_client.model_classes.deployment_properties
                                          .new.tap do |p|
              p.template = JSON.parse(template)
              p.mode = Azure::Resources::Profiles::Latest::Mgmt::Models::DeploymentMode::Complete
            end
          end
        end

        def resource_client
          mod = Azure::Resources::Profiles::Latest::Mgmt::Client
          mod.new(Config.credentials.azure)
        end
        memoize :resource_client
      end
    end
  end
end
