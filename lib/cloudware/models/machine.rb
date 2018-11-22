# frozen_string_literal: true

require 'models/application'
require 'providers/AWS'

module Cloudware
  module Models
    class Machine < Application
      TAG_PREFIX = 'cloudwareNodeID'

      attr_accessor :name, :deployment

      def tag=(tag)
        self.name = tag.sub(TAG_PREFIX, '')
      end

      def tag
        "#{TAG_PREFIX}#{name}"
      end
    end
  end
end
