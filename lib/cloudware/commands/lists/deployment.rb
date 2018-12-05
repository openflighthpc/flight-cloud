# frozen_string_literal: true

require 'stringio'
require 'pp'

module Cloudware
  module Commands
    module Lists
      class Deployment < Command
        include Concerns::Table

        def run
          Models::Context.new.deployments.each do |deployment|
            table << generate_row(deployment)
          end
          puts render_table
        end

        def table_attributes
          {
            'Deployment' => Proc.new { |d| d.name },
            'Results' => Proc.new { |d| pretty_to_s(d.results) },
            'Replacements' => Proc.new { |d| pretty_to_s(d.replacements) }
          }
        end

        def table_header
          table_attributes.keys
        end

        def generate_row(deployment)
          table_attributes.values.map do |value_proc|
            value_proc.call(deployment)
          end
        end

        def pretty_to_s(obj)
          io = StringIO.new
          PP.pp(obj, io)
          io.rewind
          io.read
        end
      end
    end
  end
end
