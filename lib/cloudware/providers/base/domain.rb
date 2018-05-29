# frozen_string_literal: true

module Cloudware
  module Providers
    module Base
      class Domain < Application
        attr_accessor :name, :region, :networkcidr, :prisubnetcidr,
                      :template, :cluster_index,
                      :create_domain_already_exists_flag

        validates_presence_of :name, :region
        validates :name, format: { with: /\A[a-zA-Z0-9-]*\z/ }
        validate :validate_networkcidr_is_ipv4
        validate :validate_prisubnetcidr_is_ipv4
        validate :validate_networkcidr_contains_prisubnetcidr
        validate :validate_domain_does_not_exist_on_create
        before_destroy :validate_cloudware_domain_exists

        def provider
          raise NotImplementedError
        end

        private

        def run_create
          raise NotImplementedError
        end

        def run_destroy
          raise NotImplementedError
        end

        def validate_cloudware_domain_exists
          return true if Providers.find_domain(provider, region, name)
          errors.add(:domain, 'does not exist')
        end

        def validate_networkcidr_is_ipv4(**h)
          validate_ipv4(:networkcidr, **h)
        end

        def validate_prisubnetcidr_is_ipv4(**h)
          validate_ipv4(:prisubnetcidr, **h)
        end

        def validate_ipv4(address_name, add_error: true)
          return true if begin
                           IPAddr.new(send(address_name)).ipv4?
                         rescue IPAddr::Error
                           false
                         end
          errors.add(address_name, 'Is not a IPv4 address') if add_error
          false
        end

        def validate_networkcidr_contains_prisubnetcidr
          return unless validate_networkcidr_is_ipv4(add_error: false)
          return unless validate_prisubnetcidr_is_ipv4(add_error: false)
          network = IPAddr.new(networkcidr)
          pri = IPAddr.new(prisubnetcidr)
          return true if network.include?(pri)
          errors.add(:prisubnetcidr,
                     'Prisubnetcidr is not within the network')
          false
        end

        def validate_domain_does_not_exist_on_create
          return unless create_domain_already_exists_flag
          errors.add(:domain, "error, '#{name}' already exists")
        end
      end
    end
  end
end
