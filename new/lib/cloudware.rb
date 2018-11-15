
# Set up Bundler, require all Gems, and then autoload everything under
# `lib/cloudware` (so don't need to inconsistently litter `require`s
# everywhere; instead, so long as things are defined in the correct, consistent
# directory structure, everything will just be autoloaded when used).
require 'bundler/setup'
Bundler.require
autoload_all 'lib/cloudware'

module Cloudware
end
