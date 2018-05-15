
module Cloudware
  module Providers
    module Base
      class Domains < Array
        class << self
          def by_region(region)
            self.new(domain_models_by_region(region))
          end

          private

          def domain_models_by_region(region)
            raise NotImplementedError
          end
        end

        def find_by_name(name)
          find { |domain| domain.name == name }
        end
      end
    end
  end
end
