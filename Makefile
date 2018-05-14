.PHONY: console
console:
	echo; bundle exec pry --exec 'require_relative "lib/cloudware.rb"'
