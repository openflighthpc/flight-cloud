
# frozen_string_literal: true

module Cloudware
  module Providers
    module Base
      class Machines < Array
        class << self
          def by_region(region)
            new(self::Builder.new(region).models)
          end

          private

          def models_by_region(_region)
            raise NotImplementedError
          end
        end

        def find_machine(domain, machine)
          find do |model|
            (model.name == machine) && (model.domain.name == domain)
          end
        end
      end
    end
  end
end
