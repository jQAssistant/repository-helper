#!/usr/bin/env ruby -w

require 'octokit'
require 'term/ansicolor'
require 'yaml'

include Term::ANSIColor

print yellow, "jQA Label Updater", reset, "\n"

repo_config_file = File.read(File.join(File.dirname(__FILE__),
                                       "../data/repositories.yaml"))
label_config_file = File.read(File.join(File.dirname(__FILE__ ),
                                            "../data/labels.yaml"))
repo_config = YAML.load(repo_config_file)
label_config = YAML.load(label_config_file)
repositories = repo_config['framework']
labels = label_config['framework']


client = Octokit::Client.new(:netrc => true)
client.auto_paginate = true

# See https://github.com/octokit/octokit.rb/issues/1057 why it is required and check this issue
# if it is still needed
# Oliver B. Fischer, 2019-11-05
client.default_media_type = "application/vnd.github.v3+json,application/vnd.github.symmetra-preview+json"

repositories.each do |r|
  repo = client.repository(r)

  print bold, white, repo.full_name
  print " (", repo.name, ") ", reset, "\n"
  existing_labels = client.labels(repo.full_name, {})
  mapped_labels = Hash[existing_labels.collect { |item| [item.name, item] }]

  labels.each_key do |label|
    label_data = labels[label]
    status_color = red
    status_color = green if mapped_labels.key?(label)

    print "\t", status_color, label, "\n"
    print "\t\tLabel exists" if mapped_labels.key?(label)
    print "\t\tLabel does not exist " unless mapped_labels.key?(label)
    print reset, "\n"

    unless mapped_labels.key?(label)
      client.add_label(repo.full_name, label, label_data['color'], {:description => label_data['description']})
      print green, "\t\tLabel has been created", reset, "\n"
    else
      client.update_label(repo.full_name, label, {:description => label_data['description'],
                                                          :color => label_data['color']})
      print green, "\t\tLabel has been updated", reset, "\n"
    end
  end
end