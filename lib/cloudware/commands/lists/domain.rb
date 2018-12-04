# frozen_string_literal: true

module Cloudware
  module Commands
    module Lists
      class Domain < Command
        include Concerns::ModelList

        private

        def deployment_method
          :domains
        end
      end
    end
  end
end
