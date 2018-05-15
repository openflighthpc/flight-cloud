
# This module isn't used by any other objects. Instead it is a reference
# for the required methods on the other provider modules

module Cloudware
  module Providers
    module Base
      class << self
        def regions
          raise NotImplementedError
        end
      end
    end
  end
end
