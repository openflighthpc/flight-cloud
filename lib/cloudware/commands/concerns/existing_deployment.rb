# frozen_string_literal: true

module Cloudware
  module Commands
    module Concerns
      module ExistingDeployment
        def deployment
          Models::Context.new.find_by_name(deployment_name).tap do |deployment|
            raise InvalidInput, <<-ERROR.squish unless deployment
              Could not find deployment '#{deployment_name}'
            ERROR
          end
        end
      end
    end
  end
end