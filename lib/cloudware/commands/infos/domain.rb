# frozen_string_literal: true

require 'tty-table'

module Cloudware
  module Commands
    module Infos
      class Domain < Info
        def model_class
          Models::Domain
        end
      end
    end
  end
end
