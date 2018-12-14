# frozen_string_literal: true

module Cloudware
  module Models
    module Concerns
      module ProviderClient
        extend Memoist

        delegate :provider, to: Config
        delegate :region, to: :context

        private

        def provider_client
          if provider == 'aws'
            require 'providers/AWS'
            mod = Providers::AWS
          else
            require 'providers/AZURE'
            mod = Providers::AZURE
          end
          mod::Client.new(region)
        end
        memoize :provider_client
      end
    end
  end
end
