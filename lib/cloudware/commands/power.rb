# frozen_string_literal: true

module Cloudware
  module Commands
    module Powers
      class Power < Command
        attr_reader :deployment_name, :machine_name

        def run
          @deployment_name = options.deployment
          @machine_name = argv[0]
          run_power
        end

        def run_power
          raise NotImplementedError
        end

        private

        def deployment
          Models::Context.new.find_by_name(deployment_name).tap do |deployment|
            raise InvalidInput, <<-ERROR.squish unless deployment
              Could not find deployment '#{deployment_name}'
            ERROR
          end
        end

        def machine
          Models::Machine.new(name: machine_name, deployment: deployment)
        end
        memoize :machine
      end
    end
  end
end
