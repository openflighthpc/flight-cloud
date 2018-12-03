# frozen_string_literal: true

module Cloudware
  module Commands
    module Powers
      class Status < Power
        def run_power(machine)
          puts machine.status
        end
      end
    end
  end
end
