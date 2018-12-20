# frozen_string_literal: true

require 'models/concerns/provider_client'
require 'models/application'
require 'models/machine'
require 'models/context'
require 'pathname'

require 'erb'

module Cloudware
  module Models
    class Deployment < Application
      include Concerns::ProviderClient

      SAVE_ATTR = [:template_path, :name, :results, :replacements].freeze
      attr_accessor(*SAVE_ATTR, :context)

      define_model_callbacks :deploy

      before_deploy :validate_replacement_tags
      before_deploy :validate_context
      before_deploy :validate_no_existing_deployment

      def template
        return raw_template unless replacements
        replacements.reduce(raw_template) do |memo, (key, value)|
          memo.gsub("%#{key}%", value.to_s)
        end
      end

      def deploy
        run_callbacks(:deploy) do
          if errors.blank?
            run_deploy
          else
            msg = ERB.new(<<~TEMPLATE, nil, '-').result(binding).chomp
              Failed to deploy resources. The following errors have occurred:
              <% errors.messages.map do |key, messages| -%>
              <% messages.each do |message| -%>
              <%= key %>: <%= message %>
              <% end -%>
              <% end -%>
TEMPLATE
            raise ModelValidationError, msg
          end
        end
      end

      def destroy
        context&.remove_deployment(self)
        provider_client.destroy(tag)
      end

      def machines
        Machine.build_from_context(self)
      end

      def to_h
        SAVE_ATTR.each_with_object({}) do |key, memo|
          memo[key] = send(key)
        end
      end

      private

      def run_deploy
        self.results = provider_client.deploy(tag, template)
      ensure
        context.with_deployment(self)
      end

      def tag
        "cloudware-deploy-#{name}"
      end

      def raw_template
        File.read(template_path)
      end

      def validate_replacement_tags
        template.scan(/%[\w-]*%/).each do |match|
          errors.add(match, 'Was not replaced in the template')
        end
      end

      def validate_context
        return if context.is_a? Cloudware::Models::Context
        errors.add(:context, 'Is not a context model')
      end

      def validate_no_existing_deployment
        return unless context.respond_to?(:find_deployment)
        return unless context.find_deployment(name)
        errors.add(:context, 'The deployment already exists')
      end
    end
  end
end
