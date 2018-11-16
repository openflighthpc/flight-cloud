
module Cloudware
  class Node < ApplicationRecord
    has_many :outputs

    validates_presence_of :name
  end
end
