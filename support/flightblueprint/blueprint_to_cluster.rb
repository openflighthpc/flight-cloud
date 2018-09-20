#!/usr/bin/env ruby
require 'yaml'

input_file = ARGV[0]

if input_file.nil?
  puts "The first argument must be a correct path to a flight blueprint yaml file"
  exit 1
end

unless File.file?(input_file)
  puts "The first argument must be a correct path to a flight blueprint yaml file"
  exit 1
end

data = YAML.load_file(input_file)
all_clusters = data.tap { |hash| hash.delete('core')}

all_clusters.each do |cluster, groups|
  ENV['CLUSTER_NAME'] = cluster
  ENV['LOGIN_NODE'] = "#{cluster}-#{groups['login']}"
  ENV['CLUSTER_GROUPS'] = groups['compute'].keys.join(' ')
  groups['compute'].each do |group, nodes|
    ENV["#{group}_NODES"] = nodes['nodes'].map{|n| "#{cluster}-#{n}"}.join(" ")
    ENV["#{group}_SEC_GROUPS"] = nodes['secondaryGroups'].delete_if{|s|s=='all'}.join(' ')
  end
  
  puts `bash /root/add-cluster.sh`
end
