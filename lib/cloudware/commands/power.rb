# frozen_string_literal: true

module Cloudware
  module Commands
    module Powers
      class Power < Command
        include Commands::Concerns::ExistingDeployment

        attr_reader :deployment_name, :identifier

        def run
          @deployment_name = options.deployment
          @identifier = argv[0]
          machines.each { |m| run_power(m) }
        end

        def run_power(machine)
          raise NotImplementedError
        end

        private

        def machines
          if options.group
            context.deployments
                   .map(&:machines)
                   .flatten
                   .select { |m| m.groups.include?(identifier) }
          else
            [Models::Machine.new(name: identifier, deployment: deployment)]
          end
        end
        memoize :machines
      end
    end
  end
end
