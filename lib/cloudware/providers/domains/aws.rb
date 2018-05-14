
module Cloudware
  module Providers
    module Domains
      class AWS < Domain
        def create_domain
          Aws2.new.create_domain(name, SecureRandom.uuid, networkcidr,
                                 prisubnetcidr, region, template: template)
        end
      end
    end
  end
end
