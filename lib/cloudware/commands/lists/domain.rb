# frozen_string_literal: true

module Cloudware
  module Commands
    module Lists
      class Domain < List
        private

        def deployment_method
          :domains
        end
      end
    end
  end
end
