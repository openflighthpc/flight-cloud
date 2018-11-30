
module Cloudware
  class ParseParam
    attr_reader :context

    def initialize(context)
      @context = context
    end

    def pair(key, value)
      return '' if value.nil? || value.empty?
      if value[0] == '*'
        name = /(?<=\A\*).*/.match(value).to_s
        context.find_by_name(name).results[key]
      else
        value.to_s
      end
    end
  end
end
