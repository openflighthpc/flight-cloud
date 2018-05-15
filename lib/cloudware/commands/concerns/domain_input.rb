
module Cloudware
  module Commands
    module Concerns
      module DomainInput
        def unpack_args
          @name = args.first
        end

        def required_options
          [:provider, :region]
        end

        private

        attr_reader :name
      end
    end
  end
end
