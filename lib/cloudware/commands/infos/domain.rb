# frozen_string_literal: true

require 'tty-table'

module Cloudware
  module Commands
    module Infos
      class Domain < Command
        include Concerns::ExistingDeployment
        include Concerns::Table
        attr_reader :domain_name, :deployment_name

        def run
          @deployment_name = options.deployment
          @domain_name = argv[0]
          machine.tags.each { |row| table << row }
          puts render_table
        end

        private

        def machine
          Models::Domain.new(name: domain_name, deployment: deployment)
        end
        memoize :machine

        def table_header
          ['Tag', 'Value']
        end
      end
    end
  end
end
