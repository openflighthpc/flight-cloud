# frozen_string_literal: true

require 'tty-table'

module Cloudware
  module Commands
    module Infos
      class Machine < Info
        def model_class
          Models::Machine
        end
      end
    end
  end
end
