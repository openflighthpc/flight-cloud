
# Hook script to allow https://github.com/voormedia/rails-erd to work for our
# non-Rails project (as it expects this file to exist and to load the app).

require_relative '../lib/cloudware'

# Eager load everything so `rails-erd` can find all models.
Dir['lib/cloudware/**/*.rb'].each do |file|
  path = File.absolute_path(file)
  require path
end
