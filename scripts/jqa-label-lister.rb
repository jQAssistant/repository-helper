#!/usr/bin/env ruby -w

require 'octokit'
require 'term/ansicolor'
require 'yaml'

include Term::ANSIColor

print yellow, "jQA Label Lister", reset, "\n"

config_file = File.read(File.join(File.dirname(__FILE__),
                                  "../data/repositories.yaml"))
config = YAML.load(config_file)
framework = config['framework']
client = Octokit::Client.new(:netrc => true)
client.auto_paginate = true

# See https://github.com/octokit/octokit.rb/issues/1057 why it is required and check this issue
# if it is still needed
# Oliver B. Fischer, 2019-11-05
client.default_media_type = "application/vnd.github.v3+json,application/vnd.github.symmetra-preview+json"

framework.each do |r|
  repo = client.repository(r)

  print bold, white, repo.full_name, " (", repo.name, ")", reset, "\n"

  client.labels(r, {:state => "all"}).each do |label|
    print "\t"
    print green
    print label.name, reset,"\n"
    print "\t\tLabeled open issue: ", label.url.gsub('api.', '').gsub('repos/', ''), "\n"
    print "\t\tEdit labels: ", label.url.gsub(/\/labels\/.*/, '/labels').gsub('api.', '').gsub('repos/', ''), "\n"
    print yellow, "\t\t", label.description
    print "\n"
  end
end

