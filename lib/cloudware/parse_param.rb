
module Cloudware
  class ParseParam
    attr_reader :context

    def initialize(context)
      @context = context
    end

    def pair(key, value)
      return '' if value.nil? || value.empty?
      if value[0] == '*'
        name = /(?<=\A\*)[^\.]*/.match(value).to_s
        other_key = /(?<=\.).*/.match(value).to_s.to_sym
        results = context.find_by_name(name)&.results || {}
        results[other_key.empty? ? key : other_key].to_s
      else
        value.to_s
      end
    end
  end
end
