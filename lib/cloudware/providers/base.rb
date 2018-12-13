# frozen_string_literal: true

require 'spinner'

module Cloudware
  module Providers
    module Base
      module HasCredentials
        def credentials
          self.class.parent::Credentials.build
        end
      end

      class Credentials
        def self.build
          raise NotImplementedError
        end
      end

      class Machine
        extend Memoist
        include HasCredentials

        attr_reader :machine_id, :region

        def initialize(machine_id, region)
          @machine_id = machine_id
          @region = region
        end

        def status
          raise NotImplementedError
        end

        def off
          raise NotImplementedError
        end

        def on
          raise NotImplementedError
        end
      end

      class Client
        extend Memoist
        include HasCredentials
        include WithSpinner

        attr_reader :region

        def initialize(region)
          @region = region
        end

        def deploy(_tag, _template)
          raise NotImplementedError
        end

        def destroy(_tag)
          raise NotImplementedError
        end

        def machine(id)
          self.class.parent::Machine.new(id, region)
        end
      end
    end
  end
end
