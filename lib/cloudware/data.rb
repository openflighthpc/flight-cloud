# frozen_string_literal: true

require 'yaml'
require 'fileutils'

module Cloudware
  class Data
    DEFAULT_VALUE = {}.freeze

    class << self
      def load(file, default_value: DEFAULT_VALUE)
        str = File.exist?(file) ? File.read(file) : ''
        load_string(str, default_value: default_value)
      end

      def load_string(string, default_value: DEFAULT_VALUE)
        raw = convert_keys(YAML.load(string))
        raw ? raw : default_value
      end

      def dump(file, data)
        FileUtils.mkdir_p(File.dirname(file))
        File.write(file, YAML.dump(data))
      end

      private

      def convert_keys(obj)
        case obj
        when Hash
          obj.deep_symbolize_keys
        when Enumerable
          obj.map { |sub_obj| convert_keys(sub_obj) }
        else
          obj
        end
      end
    end
  end
end
