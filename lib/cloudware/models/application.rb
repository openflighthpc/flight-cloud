# frozen_string_literal: true

module Cloudware
  module Models
    class Application
      class << self
        alias_method 'build', 'new'
      end

      include ActiveModel::Model

      def initialize(*_a, **parameters)
        @errors = ActiveModel::Errors.new(self)
        parameters.each do |key, value|
          public_send("#{key}=", value)
        end
      end
    end
  end
end
