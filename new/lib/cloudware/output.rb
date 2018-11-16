
module Cloudware
  class Output < ApplicationRecord
    belongs_to :deployment
    belongs_to :node, optional: true

    validates_presence_of :name
    validates_presence_of :value
  end
end
