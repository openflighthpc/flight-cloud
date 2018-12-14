
module Cloudware
  class ParamParser
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

    def string(input)
      input.split('=', 2).tap do |array|
        raise InvalidInput, <<-ERROR.squish unless array.length == 2
          '#{input}' does not form a key value pair
        ERROR
        array[0] = array[0].to_sym
        array[1] = pair(array[0], array[1])
      end
    end
  end
end
