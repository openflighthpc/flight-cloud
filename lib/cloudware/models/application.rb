
module Cloudware
  module Models
    class Application
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
