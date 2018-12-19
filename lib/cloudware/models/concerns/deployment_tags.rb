# frozen_string_literal: true

#
# =============================================================================
# Copyright (C) 2018 Stephen F. Norledge and Alces Software Ltd
#
# This file is part of Alces Cloudware.
#
# Alces Cloudware is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Alces Cloudware is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Alces Cloudware.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on the Alces Cloudware, please visit:
# https://github.com/alces-software/cloudware
# ==============================================================================
#

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
