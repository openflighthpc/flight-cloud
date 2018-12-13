# frozen_string_literal: true

module Cloudware
  module Commands
    module Concerns
      module ExistingDeployment
        def deployment
          context.find_deployment(deployment_name).tap do |deployment|
            raise InvalidInput, <<-ERROR.squish unless deployment
              Could not find deployment '#{deployment_name}'
            ERROR
          end
        end
      end
    end
  end
end
