
# frozen_string_literal: true

module Cloudware
  module Commands
    class List < Command
      include Concerns::Table
      include Concerns::ModelList
    end
  end
end
