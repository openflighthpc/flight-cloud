
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

      def create
        run_callbacks(:create) do
          run_create if valid?
        end
        self
      end

      def create!
        create
        return self if valid?
        raise ModelValidationError, errors.full_messages.join("\n")
      end

      private

      define_model_callbacks :create

      def run_create(*_a)
        raise NotImplementedError
      end
    end
  end
end
