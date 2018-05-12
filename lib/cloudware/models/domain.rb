
module Cloudware
  module Models
    class Domain < Application
      attr_accessor :name
      validates_presence_of :name
    end
  end
end
