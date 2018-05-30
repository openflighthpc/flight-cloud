
module Cloudware
  module Providers
    module AZURE
      module Helpers
        class AzureClient
          def resource
            @resource ||= begin
              Azure::Resources::Profiles::Latest::Mgmt::Client.new(
                Cloudware.config.credentials.azure
              )
            end
          end
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
