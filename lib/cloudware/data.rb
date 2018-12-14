# frozen_string_literal: true

require 'yaml'
require 'fileutils'

module Cloudware
  class Data
    class << self
      def load(file)
        load_string(File.read(file))
      end

      def load_string(string)
        YAML.load(string).deep_symbolize_keys
      end

      def dump(file, data)
        FileUtils.mkdir_p(File.dirname(file))
        File.write(file, YAML.dump(data.to_h))
      end
    end
  end
end
