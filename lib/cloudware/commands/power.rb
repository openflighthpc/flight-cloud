# frozen_string_literal: true

module Cloudware
  module Commands
    module Powers
      class Power < Command
        include Commands::Concerns::ExistingDeployment

        attr_reader :deployment_name, :machine_name

        def run
          @deployment_name = options.deployment
          @machine_name = argv[0]
          machines.each { |m| run_power(m) }
        end

        def run_power(machine)
          raise NotImplementedError
        end

        private

        def machines
          if options.group
            raise NotImplementedError
          else
            [Models::Machine.new(name: machine_name, deployment: deployment)]
          end
        end
        memoize :machines
      end
    end
  end
end
