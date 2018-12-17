# frozen_string_literal: true

module Cloudware
  module Commands
    module Lists
      class Machine < Command
        include Concerns::MarkdownTemplate

        TEMPLATE = <<-TEMPLATE
<% if machines.empty? -%>
No machines found
<% end -%>
<% machines.each do |machine| -%>
# Machine: '<%= machine.name %>'
<% machine.tags.each do |key, value| -%>
- *<%= key %>*: <%= value %>
<% end -%>

<% end -%>
TEMPLATE
      end
    end
  end
end
