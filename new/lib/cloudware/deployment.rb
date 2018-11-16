
module Cloudware
  class Deployment < ApplicationRecord
    PLATFORMS = ['aws', 'azure']

    has_many :outputs
    has_many :nodes, through: :outputs

    validates_presence_of :name
    validates_presence_of :template
    validates :platform, presence: true, inclusion: { in: PLATFORMS }
  end
end
