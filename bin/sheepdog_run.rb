#! /usr/bin/env ruby
#
# sheepdog_run executes a command and sends its result into a
# monitoring queue. This runner is typically used in scripts or to
# wrap CRON jobs. It will send a message into a redis 'queue', e.g.
# on failure.
#
# To view members you can run redis-cli with
#
#   redis-cli  Smembers sheepdog:run
#
# or use sheepdog_list.rb

$: << 'lib'

require 'optparse'
require 'ostruct'
require 'sheepdog'

options = {
  cmd: 'echo "Hello world"',
  channel: 'run',
  host: 'localhost',
  port: 6379 # redis port
}
OptionParser.new do |opts|
  opts.banner = "Usage: sheepdog_run.rg [options]"

  opts.on("-c", "--cmd full", "Run command") do |cmd|
    options[:cmd] = cmd
  end
  opts.on("--always", "Always report SUCC or FAIL") do |always|
    options[:always] = always
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
  opts.on("-t", "--tag tag", "Set message tag") do |tag|
    options[:tag] = tag
  end
  opts.on("--log [file]", "Also log output to file (default sheepdog.log)") do |log|
    log = "sheepdog.log" if not log
    options[:log] = log
  end
  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end
end.parse!

p options if options[:verbose]
opts = OpenStruct.new(options)

r = redis_connect(opts)

event = run(opts.tag,opts.cmd)

redis_report(r,event,opts)
