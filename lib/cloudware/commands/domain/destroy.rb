# frozen_string_literal: true

module Cloudware
  module Commands
    module Domain
      class Destroy < Command
        def run
          d = Cloudware::Domain.new

          options.name = ask('Domain name: ') if options.name.nil?
          d.name = options.name.to_s

          Whirly.start status: 'Checking domain exists'
          raise("Domain name #{options.name} does not exist") unless d.exists?
          Whirly.stop

          Whirly.start status: "Destroying domain #{options.name}"
          d.destroy
          Whirly.stop
        end
      end
    end
  end
end
