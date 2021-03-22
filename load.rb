#!/usr/bin/env ruby

require 'colorize'
require 'elasticsearch'
require 'json'
require 'openssl'
require 'progress_bar'
require 'slop'

# 
# API
#
# https://rubydoc.info/gems/elasticsearch-api/Elasticsearch/API/Indices/Actions
#

opts = Slop::Options.new
opts.string '-n', '--name', 'Name of index', required: true
opts.bool '-r', '--reindex', 'Reindex (delete, create, index)'
opts.bool '-c', '--create', 'Create the index'
opts.bool '-d', '--delete', 'Delete the index'
opts.bool '-i', '--import', 'Import the index'
opts.bool '-s', '--status', 'Get cluster status'

begin
  parsed = opts.parse ARGV
rescue => e
  puts "\nError: #{e.to_s}\n\n"
  puts opts
  exit
end

if ARGV.length < 2
  puts opts
  exit
end

index = parsed[:name]

if ENV['ELASTIC_HOST'] == nil
  puts "Please create and source .env (see README)"
  exit
end

client = Elasticsearch::Client.new(
  user: ENV['ELASTIC_USER'],
  password: ENV['ELASTIC_PASSWORD'],
  host: ENV['ELASTIC_HOST'],
  scheme: 'https',
  port: 9243)

if parsed[:delete] || parsed[:reindex]
  puts "Deleting index for #{parsed[:name]} ..."
  client.indices.delete index: index
end

if parsed[:create] || parsed[:reindex]
  puts "Creating index for #{parsed[:name]} ..."
  settings = {
    number_of_shards: 1,
    number_of_replicas: 1,
    refresh_interval: "1s"
  }
  mappings = {
    dynamic: "true",
    properties: {
      "dt": {
        type: "date"
      }
    }
  }
  client.indices.create(index: index,
    body: {
      settings: settings,
      mappings: mappings
    })
end

if parsed[:index] || parsed[:reindex]
  puts "Importing #{parsed[:name]} in batches of 100 ..."
  file = File.read("data/#{index}.json")
  data = JSON.parse(file)
  bar = ProgressBar.new(data.count/100)
  data.each_slice(100) do |group|
    batch_for_bulk = []
    group.each do |d|
      if d['weather'][0]
        d['conditions'] = d['weather'][0]['main']
        d['description'] = d['weather'][0]['description'] 
      end
      d.delete('weather')
      # Elasticsearch datetime detector expects Unix Time in ms (not sec)
      d['dt'] = d['dt'] * 1000
      batch_for_bulk.push({ index: { _index: index } }.to_json)
      batch_for_bulk.push(d.to_json)
    end
    results = client.bulk(
      index: index,
      body: batch_for_bulk
    )
    #puts JSON.pretty_generate(results)
    #exit
    bar.increment!
  end
end

if parsed[:status] || parsed[:reindex]
  print "\nGetting cluster status ... "
  start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  health = client.cluster.health
  finish = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  diff = finish - start # gets time is seconds as a float
  if health['status'] == 'green'
    puts 'green'.light_green
    puts "Took #{'%0.4f' % diff} ms"
  elsif health['status'] == 'yellow'
    puts 'yellow'.light_yellow
    puts "Took #{'%0.4f' % diff} ms"
  elsif health['status'] == 'red'
    puts 'red'.light_red
    puts "Took #{'%0.4f' % diff} ms"
  end
  puts
end

