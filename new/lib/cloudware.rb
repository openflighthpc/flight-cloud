
# Set up Bundler, require all Gems, and then autoload everything under
# `lib/cloudware` (so don't need to inconsistently litter `require`s
# everywhere; instead, so long as things are defined in the correct, consistent
# directory structure, everything will just be autoloaded when used).
require 'bundler/setup'
Bundler.require
autoload_all 'lib/cloudware'

# Similar to how `config/database.yml` is loaded in Rails (see
# https://stackoverflow.com/a/24323612/2620402).
database_config = YAML.load ERB.new(IO.read('db/config.yml')).result
ActiveRecord::Base.configurations = database_config

environment = ENV.fetch('APP_ENV', :development)
ActiveRecord::Base.establish_connection(environment)


module Cloudware
end
