
# frozen_string_literal: true

require_all 'lib/cloudware/providers/base/*.rb'
require_all 'lib/cloudware/providers/**/*.rb'

module Cloudware
  module Providers
    class << self
      def select(provider)
        case provider
        when 'aws'
          AWS
        when 'azure'
          raise NotImplementedError
        else
          raise InvalidInput, "Unrecognised provider: #{provider}"
        end
      end
    end
  end
end
