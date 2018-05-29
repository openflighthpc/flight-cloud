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

        include Helpers::Client

        def run_create
          client.resources
        end

        def id
          @id ||= SecureRandom.uuid
        end
      end
    end
  end
end
