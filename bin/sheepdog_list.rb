#! /usr/bin/env ruby
#
# sheepdog_list prints the queueu
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
  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end

end.parse!

p options if options[:verbose]

opts = OpenStruct.new(options)

r = Redis.new()
begin
  r.get("just testing@")
rescue Redis::CannotConnectError
  error("redis is not connecting")
end

channel = "sheepdog:"+opts.channel

r.smembers(channel).each do | buf |
  e = OpenStruct.new(eval(buf))
  tag = if e.tag
          e.tag
        else
          e.command
        end
  if e.elapsed
    min = sprintf("%.2d",e.elapsed/60)
    sec = sprintf("%.2d",e.elapsed % 60)
  end
  print("#{e.time} (#{e.host}) #{e.err} #{e.status} <#{min}m#{sec}s> #{tag}")
  print("\n")
end
puts("For more info try: redis-cli  Smembers sheepdog:run")
