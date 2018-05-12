
module Cloudware
  module Models
    class Application
      include ActiveModel::Model

      def initialize(*_a, **_h)
        @errors = ActiveModel::Errors.new(self)
      end
    end
  end
end
