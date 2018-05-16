
# frozen_string_literal: true

module Cloudware
  module Commands
    module Concerns
      module DomainInput
        def unpack_args
          @name = args.first
        end

        private

        attr_reader :name
      end
    end
  end
end
