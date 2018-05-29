# frozen_string_literal: true

require 'azure_mgmt_resources'
require 'azure_mgmt_compute'
require 'azure_mgmt_network'

module Cloudware
  module Providers
    module AZURE
      class Domain < Base::Domain
        def provider
          'azure'
        end

        private

        def run_create
        end

        def id
          @id ||= SecureRandom.uuid
        end

        def resources_client
          @resources_client ||= begin
            Azure::Resources::Profiles::Latest::Mgmt::Client.new(
              Cloudware.config.credentials.azure
            )
          end
        end
      end
    end
  end
end
