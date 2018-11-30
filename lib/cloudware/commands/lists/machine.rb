# frozen_string_literal: true

module Cloudware
  module Commands
    module Lists
      class Machine < List
        private

        def deployment_method
          :machines
        end
      end
    end
  end
end
