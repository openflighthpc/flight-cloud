
module Cloudware
  module Models
    class Machine < Application
      ATTRIBUTES = [:name, :type, :flavour, :domain, :role, :priip]
      attr_accessor(*ATTRIBUTES)
    end
  end
end
