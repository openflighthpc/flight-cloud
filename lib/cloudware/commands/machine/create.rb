# frozen_string_literal: true

module Cloudware
  module Commands
    module Machine
      class Create < Command
        def run
          domain
          machine = Cloudware::Models::Machine.build(
            name: name,
            type: options.type,
            flavour: options.flavour,
            domain: domain,
            role: options.role,
            priip: options.role
          )

          m = Cloudware::Machine.new

          m.type = options.type.to_s
          m.flavour = options.flavour.to_s
          m.name = name
          m.domain = options.domain
          m.role = options.role
          m.priip = options.priip.to_s

          run_whirly('Creating new deployment') do
            m.create
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
            run_whirly('Searching for domain') do
              Providers.find_domain(
                options.provider, options.region, options.domain
              )
            end
          end
          return @domain if @domain
          raise InvalidInput, "Can not find '#{options.domain}' domain"
        end
      end
    end
  end
end
