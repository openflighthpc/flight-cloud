
# frozen_string_literal: true

module Cloudware
  module Providers
    module Base
      class Machines < Array
        class << self
          def by_region(region)
            new(models_by_region(region))
          end

          private

          def models_by_region(_region)
            raise NotImplementedError
          end
        end

        def find_by_name(name)
          find { |model| model.name == name }
        end
      end
    end
  end
end
