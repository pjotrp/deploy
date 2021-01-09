#! /usr/bin/env ruby
#
# sheepdog_list prints the queue
#

require 'json'
require 'optparse'
require 'ostruct'
require 'redis'

def error(msg)
  $stderr.print("ERROR: "+msg+" (sheepdog)\n")
  exit(1)
end

options = {
  channel: 'run'
}
OptionParser.new do |opts|
  opts.banner = "Usage: sheepdog_list.rg [options]"

  opts.on("-c", "--cmd full", "Run command") do |cmd|
    options[:cmd] = cmd
  end
  opts.on("--[no-]json", "Output valid JSON") do |json|
    options[:json] = json
  end
  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end

end.parse!

verbose = options[:verbose]
p options if verbose

opts = OpenStruct.new(options)

r = Redis.new()
begin
  r.get("just testing@")
rescue Redis::CannotConnectError
  error("redis is not connecting")
end

channel = "sheepdog:"+opts.channel

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
  if e.elapsed
    min = sprintf("%.2d",e.elapsed/60)
    sec = sprintf("%.2d",e.elapsed % 60)
  end
  if opts.json
    print(",") if i>0
    print(buf)
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
