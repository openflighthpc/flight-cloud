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

        def machine
          deployment.machines
                    &.find { |m| m.name == machine_name }
                    .tap do |machine|
            raise InvalidInput, <<-MISSING.squish if machine.nil?
              Could not locate node '#{machine_name}' within deployment
              '#{deployment_name}'
            MISSING
          end
        end
      end
    end
  end
end
