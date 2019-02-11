# frozen_string_literal: true

require 'tty-color'
require 'tty-markdown'

module Cloudware
  module Commands
    module Concerns
      module MarkdownTemplate
        RenderCluster = Struct.new(:cluster_identifier) do
          delegate :deployments, to: :cluster
          delegate :machines, to: :deployments

          def cluster
            @cluster ||= Cluster.read(cluster_identifier)
          end

          def render(template, verbose: false)
            ERB.new(template, nil, '-').result(binding)
          end
        end

        def run
          puts TTY::Markdown.parse(rendered_markdown)
        end

        def rendered_markdown
          RenderCluster.new(__config__.current_cluster)
                       .render(self.class::TEMPLATE, verbose: options.verbose)
        end
      end
    end
  end
end
