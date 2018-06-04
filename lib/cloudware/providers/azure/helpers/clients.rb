
module Cloudware
  module Providers
    module AZURE
      module Helpers
        class AzureClient
          extend Memoist

          def resource
            Azure::Resources::Profiles::Latest::Mgmt::Client.new(
              Cloudware.config.credentials.azure
            )
          end
          memoize :resource

          def network
            Azure::Network::Profiles::Latest::Mgmt::Client.new(
              Cloudware.config.credentials.azure
            )
          end
          memoize :network
        end

        module Client
          def client
            @client ||= AzureClient.new
          end
        end
      end
    end
  end
end
