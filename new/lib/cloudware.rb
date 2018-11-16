
# Set up Bundler, require always needed Gems, and then autoload everything
# under `lib/cloudware` (so don't need to inconsistently litter `require`s
# everywhere; instead, so long as things are defined in the correct, consistent
# directory structure, everything will just be autoloaded when used). Note:
# `$DEBUG = true` can be used to debug auto-loading.
require 'bundler/setup'

require 'require_all'
require 'active_record'

autoload_all 'lib/cloudware'

# Similar to how `config/database.yml` is loaded in Rails (see
# https://stackoverflow.com/a/24323612/2620402).
database_config = YAML.load ERB.new(IO.read('db/config.yml')).result
ActiveRecord::Base.configurations = database_config

environment = ENV.fetch('APP_ENV', :development)
ActiveRecord::Base.establish_connection(environment)


module Cloudware
end
