
module Cloudware
  module Domains
    class << self
      def list
        @list ||= begin
                    @list = {}
                    Cloudware.config.providers.each do |provider|
                      @list.merge!(load_domain(provider))
                    end
                    @list
                  end
      end

      private

      # TODO: Do not use `Domain` to load a cloud to contain a list of
      # domains. It is just weird
      def load_domain(provider)
        d = Domain.new
        d.provider = provider
        d.cloud.domains
      end
    end
  end
end
