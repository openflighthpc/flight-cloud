# frozen_string_literal: true

require 'yaml'
require 'fileutils'

module Cloudware
  class Data
    class << self
      def dump(file, data)
        FileUtils.mkdir_p(File.dirname(file))
        File.write(file, YAML.dump(data.to_h))
      end
    end
  end
end
