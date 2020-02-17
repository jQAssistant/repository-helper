#!/usr/bin/env ruby -w

require 'octokit'
require 'term/ansicolor'
require 'time'
require 'yaml'

include Term::ANSIColor

# https://nandovieira.com/working-with-dates-on-ruby-on-rails

print yellow, "jQA Milestone Updater", reset, "\n"

repo_config_file = File.read(File.join(File.dirname(__FILE__),
                                       "../data/repositories.yaml"))
milestone_config_file = File.read(File.join(File.dirname(__FILE__ ),
                                            "../data/milestones.yaml"))
repo_config = YAML.load(repo_config_file)
milestones = YAML.load(milestone_config_file)

repositories = repo_config['framework']

client = Octokit::Client.new(:netrc => true)
client.auto_paginate = true

repositories.each do |r|
  repo = client.repository(r)
  repo_creation = repo.created_at

  print bold, white, repo.full_name
  print " (", repo.name, ") ", reset, "\n"
  existing_milestones = client.milestones(repo.full_name, {:state => "all"})
  mapped_milestones = Hash[existing_milestones.collect { |item| [item.title, item] }]

  milestones.each_key do |milestone|
    ms = milestones[milestone]
    status_color = red
    status_color = green if mapped_milestones.key?(milestone)

    print "\t", status_color, milestone, "\n"
    print "\t\tMilestone exists" if mapped_milestones.key?(milestone)
    print "\t\tMilestone does not exist " unless mapped_milestones.key?(milestone)
    print reset, "\n"

    if repo_creation.to_date > ms['notAfter']
      print red, "\t\tMilestone has been defined before the creation of the repository\n", reset
      next
    end


    unless mapped_milestones.key?(milestone)
      client.create_milestone(repo.full_name, milestone, {:description => ms['description']})
      print green, "\t\tMilestone has been created", reset, "\n"
    else
      current_milestone = mapped_milestones[milestone]

      client.update_milestone(repo.full_name, current_milestone.number, {:description => ms['description']})
      print green, "\t\tMilestone has been updated", reset, "\n"
    end
  end
end