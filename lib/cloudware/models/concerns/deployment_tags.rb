# frozen_string_literal: true

module Cloudware
  module Models
    module Concerns
      module ModelTags
        # NOTE: The TAG_TYPE must be set as a constant on the base model

        def self.included(base)
          base.extend(ClassMethods)
        end

        module ClassMethods
          def flag
            'TAG'
          end

          def build_from_context(context)
            (context.results || {})
              .keys
              .map { |k| name_from_tag(k) }
              .uniq
              .reject(&:nil?)
              .map do |name|
              new(name: name, context: context)
            end
          end

          def name_from_tag(tag)
            regex = /\A.*(?=#{flag}.*\Z)/
            regex.match(tag.to_s)&.to_a&.first
          end

          def tag_generator(name, tag)
            :"#{name}#{flag}#{tag}"
          end
        end

        attr_accessor :name, :context

        def tags
          (context.results || {}).each_with_object({}) do |(key, value), memo|
            next unless (tag = extract_tag(key))
            memo[tag] = value
          end
        end

        def tag_generator(tag)
          self.class.tag_generator(name, tag)
        end

        def extract_tag(key)
          regex = /(?<=\A#{self.class.tag_generator(Regexp.escape(name), '')}).*/
          regex.match(key.to_s)&.to_a&.first&.to_sym
        end

        def fetch_result(short_tag, default: nil)
          long_tag = tag_generator(short_tag)
          result = (context.results || {})[long_tag]
          return result unless result.nil?
          return default unless default.nil?
          yield long_tag if block_given?
        end
      end
    end
  end
end
