# frozen_string_literal: true

require 'models/concerns/provider_client'
require 'models/application'
require 'models/machine'
require 'models/context'
require 'pathname'

module Cloudware
  module Models
    class Deployment < Application
      include Concerns::ProviderClient

      SAVE_ATTR = [:template_name, :name, :results, :replacements]
      attr_accessor(*SAVE_ATTR)
      attr_reader :context

      define_model_callbacks :deploy

      before_deploy :validate_replacement_tags

      def context=(input)
        @context = input.tap { |c| c.with_deployment(self) }
      end

      def template
        return raw_template unless replacements
        replacements.reduce(raw_template) do |memo, (key, value)|
          memo.gsub("%#{key}%", value.to_s)
        end
      end

      def deploy
        run_callbacks(:deploy) do
          if errors.blank?
            self.results = provider_client.deploy(tag, template)
          else
            raise ModelValidationError, <<-ERROR.strip_heredoc.chomp
              Failed to deploy resources. The following errors have occurred:
              #{errors.messages.map { |k, v| "#{k}: #{v.first}" }.join("\n")}
            ERROR
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

      def tag
        "cloudware-deploy-#{name}"
      end

      def template_path
        return template_name if Pathname.new(template_name).absolute?
        ext = (provider == 'aws' ? '.yaml' : '.json')
        File.join(
          Config.content_path,
          'templates',
          provider,
          "#{template_name}#{ext}"
        )
      end

      def raw_template
        File.read(template_path)
      end

      def validate_replacement_tags
        /%[\w-]*%/.match(template).to_a.each do |match|
          errors.add(match, 'Was not replaced in the template')
        end
      end
    end
  end
end
