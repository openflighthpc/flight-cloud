# frozen_string_literal: true

module Cloudware
  module Commands
    module Powers
      class Power < Command
        attr_reader :deployment_name, :machine_name

        def run
          @deployment_name = argv[0]
          @machine_name = argv[1]
          run_power
        end

        def run_power
          raise NotImplementedError
        end

        def deployment
          Models::Deployment.build(name: deployment_name)
        end
        memoize :deployment
      end
    end
  end
end
