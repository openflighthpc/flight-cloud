# frozen_string_literal: true

module Cloudware
  module Models
    module Concerns
      module ProviderClient
        extend Memoist

        private

        def provider_client
          Providers::AWS::Client.new(region)
        end
        memoize :provider_client
      end
    end
  end
end
