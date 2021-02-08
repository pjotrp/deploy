#! /usr/bin/env ruby
#
# Ping redis - always reports SUCCESS and never FAIL (because that is
# when a connection fails. This allows for an expect monitor on the
# receiver.
#
# This is to have a consistent method for making sure the redis
# connection works (and machines are up).

rootpath = File.dirname(File.dirname(__FILE__))
$: << File.join(rootpath,'lib')

require 'optparse'
require 'ostruct'
require 'sheepdog'

options = {
  always: true,
  verbose: true,
  cmd: 'echo "Hello world"',
  channel: 'run',
  tag: 'PING',
  host: 'localhost',
  port: 6379 # redis port
}
OptionParser.new do |opts|
  opts.banner = "Usage: sheepdog_run.rg [options]"

  opts.on("-h", "--host name", "Attach to redis on host") do |host|
    options[:host] = host
  end
  opts.on("-p", "--port num", Integer, "Attach to redis on port") do |port|
    options[:port] = port
  end
  opts.on("--password str", "Attach to redis with password") do |pwd|
    redis_password = pwd
  end
  opts.on("-t", "--tag tag", "Set message tag") do |tag|
    options[:tag] = 'PING '+tag
  end
  opts.on("--log [file]", "Also log output to file (default sheepdog.log)") do |log|
    log = "sheepdog.log" if not log
    options[:log] = log
  end
  opts.on("-v", "--[no-]verbose", "Run verbosely (--no-verbose is quiet mode)") do |v|
    options[:verbose] = v
  end

end.parse!

verbose = options[:verbose]
p options if verbose

opts = OpenStruct.new(options)

r = redis_connect(opts)

event = sheepdog_ping(opts.tag,r)

redis_report(r,event,opts)
