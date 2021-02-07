#! /usr/bin/env ruby
#
# sheepdog_list prints the queue
#

rootpath = File.dirname(File.dirname(__FILE__))
$: << File.join(rootpath,'lib')

require 'json'
require 'optparse'
require 'ostruct'
require 'redis'
require 'sheepdog'

options = {
  channel: 'run',
  host: 'localhost',
  port: 6379 # redis port
}
OptionParser.new do |opts|
  opts.banner = "Usage: sheepdog_list.rg [options]"

  opts.on("-c", "--cmd full", "Run command") do |cmd|
    options[:cmd] = cmd
  end
  opts.on("--[no-]json", "Output valid JSON") do |json|
    options[:json] = json
  end
  opts.on("--status", "Output status") do |status|
    options[:status] = status
  end
  opts.on("-h", "--host name", "Attach to redis on host") do |host|
    options[:host] = host
  end
  opts.on("-p", "--port num", Integer, "Attach to redis on port") do |port|
    options[:port] = port
  end
  opts.on("--password str", "Attach to redis with password") do |pwd|
    redis_password = pwd
  end
  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end

end.parse!

verbose = options[:verbose]
p options if verbose
opts = OpenStruct.new(options)

r = redis_connect(opts)

channel = "sheepdog:"+opts.channel

status = {}

print("[") if opts.json
r.smembers(channel).sort.each_with_index do | buf,i |
  begin
    json = JSON::parse(buf)
    e = OpenStruct.new(json)
  rescue JSON::ParserError
    next
  end
  tag = if e.tag
          e.tag
        else
          e.command
        end
  status[tag] = {time: e.time, host: e.host, status: e.err}
  if e.elapsed
    min = sprintf("%.2d",e.elapsed/60)
    sec = sprintf("%.2d",e.elapsed % 60)
  end
  if opts.json
    print(",") if i>0
    print(buf)
  elsif opts.status
    # skip
  else
    print("#{e.time} (#{e.host}) #{e.err} #{e.status} <#{min}m#{sec}s> #{tag}")
    print("\n")
  end
end
if opts.json
  print("]")
else
  puts("For more info try: redis-cli  Smembers sheepdog:run") if verbose
end

if opts.status
  list = []
  status.each_pair { |e|
    k,v = e
    v['tag'] = k
    list.push(v)
  }
  print(list.to_json)
end
