#!/usr/bin/env ruby -w

require 'octokit'
require 'term/ansicolor'
require 'yaml'

include Term::ANSIColor

print yellow, "jQA Milestone Lister", reset, "\n"

config_file = File.read(File.join(File.dirname(__FILE__),
                                  "../data/repositories.yaml"))
config = YAML.load(config_file)
framework = config['framework']
client = Octokit::Client.new(:netrc => true)
client.auto_paginate = true

framework.each do |r|
  repo = client.repository(r)

  print bold, white, repo.full_name, " (", repo.name, ")", reset, "\n"

  client.milestones(r, {:state => "all"}).each do |milestone|
    status_color = white
    status_color = green if milestone.state == "open"
    open_color = reset
    open_color = red if milestone.open_issues > 0 and milestone.state != "open"

    print "\t"
    print status_color
    print milestone.title, " (", milestone.state, ") "
    print reset
    print "(issues ", open_color, milestone.open_issues, " open, "
    print reset, milestone.closed_issues, " closed) "
    print "(Due date ", milestone.due_on, ") " if milestone.due_on?
    print reset, milestone.html_url
    print "\n"
  end
end

