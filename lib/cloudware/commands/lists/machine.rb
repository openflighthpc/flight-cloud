# frozen_string_literal: true

module Cloudware
  module Commands
    module Lists
      class Machine < List
        private

        def context_method
          :machines
        end
      end
    end
  end
end
