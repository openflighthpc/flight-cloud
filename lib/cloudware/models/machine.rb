# frozen_string_literal: true

require 'models/application'
require 'providers/AWS'

module Cloudware
  module Models
    class Machine < Application
      TAG_PREFIX = 'cloudwareNodeID'

      attr_accessor :name, :deployment
    end
  end
end
