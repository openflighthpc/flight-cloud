
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

      def create(*a)
        run_callbacks(:create) do
          run_create(*a) if valid?
        end
        self
      end

      private

      define_model_callbacks :create

      def run_create(*_a)
        raise NotImplementedError
      end
    end
  end
end
