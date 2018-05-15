
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
          raise InternalError, "Unrecognised provider: #{provider}"
        end
      end
    end
  end
end
