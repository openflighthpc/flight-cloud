# frozen_string_literal: true

require 'providers/AWS'
require 'providers/AZURE'

module Cloudware
  module Models
    module Concerns
      module ProviderClient
        extend Memoist

        delegate :provider, :region, to: Config

        private

        def provider_client
          mod = (provider == 'aws' ? Providers::AWS : Providers::AZURE)
          mod::Client.new(region)
        end
        memoize :provider_client
      end
    end
  end
end
