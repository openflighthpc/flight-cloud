# frozen_string_literal: true

require 'yaml'
require 'fileutils'

module Cloudware
  class Data
    DEFAULT_VALUE = {}

    class << self
      def load(file, default_value: DEFAULT_VALUE)
        str = File.exists?(file) ? File.read(file) : ''
        load_string(str, default_value: default_value)
      end

      def load_string(string, default_value: DEFAULT_VALUE)
        raw = YAML.load(string).deep_symbolize_keys
        raw.nil? ? default_value : raw
      end

      def dump(file, data)
        FileUtils.mkdir_p(File.dirname(file))
        File.write(file, YAML.dump(data.to_h))
      end
    end
  end
end
