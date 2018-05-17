# frozen_string_literal: true

module Cloudware
  module Commands
    module Machine
      class Create < Command
        def run
          run_whirly('Creating new deployment') do
            Cloudware::Models::Machine.build(
              domain: domain,
              name: name,
              type: options.type,
              flavour: options.flavour,
              role: options.role,
              priip: options.priip
            ).create!
          end
        end

        def unpack_args
          @name = args.first
        end

        private

        attr_reader :name

        def required_options
          [:domain, :role, :priip, :flavour, :type]
        end

        def domain
          @domain ||= begin
            Providers.find_domain(
              options.provider, options.region, options.domain
            )
          end
          return @domain if @domain
          raise InvalidInput, "Can not find '#{options.domain}' domain"
        end
      end
    end
  end
end
