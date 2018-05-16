# frozen_string_literal: true

module Cloudware
  module Providers
    module Base
      class Machine
        def initialize(machine_model)
          @machine_model = machine_model
        end

        def create
          raise NotImplementedError
        end

        def destroy
          raise NotImplementedError
        end

        private

        attr_reader :machine_model

        delegate(*Models::Machine.delegate_attributes, to: :machine_model)
      end
    end
  end
end
