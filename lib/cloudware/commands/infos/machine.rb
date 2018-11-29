# frozen_string_literal: true

module Cloudware
  module Commands
    module Infos
      class Machine < Command
        include Concerns::ExistingDeployment

        def run
          @deployment_name = options.deployment
        end
      end
    end
  end
end
