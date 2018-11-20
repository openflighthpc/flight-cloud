# frozen_string_literal: true

module Cloudware
  module Providers
    class AWS
      class << self
        attr_reader :credentials

        def deploy(template)
        end
      end

      @credentials = Config.credentials.aws
    end
  end
end
