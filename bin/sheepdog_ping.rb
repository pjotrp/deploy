#! /usr/bin/env ruby
#
# Ping redis - always reports SUCCESS and never FAIL (because
# that is when a connection fails. Use an expect monitor.
#
# This is to have a consistent method for making sure the
# redis connection works (and machines are up).

require 'json'
require 'open3'
require 'optparse'
require 'ostruct'
require 'redis'
require 'socket'

error_msg = nil
errval = 0

def error(msg)
  error_msg = "ERROR: "+msg+" (sheepdog)"
  errval = 1
end

# Read options file
CONFIGFN = ENV['HOME']+"/.redis.conf"
if File.exist?(CONFIGFN)
  CONFIG = JSON.parse(File.read(ENV['HOME']+"/.redis.conf"))
end

redis_password = nil
options = {
  always: true,
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

verbose = options[:verbose]
p options if verbose

opts = OpenStruct.new(options)

if CONFIG and opts.host and not redis_password
  if CONFIG.has_key?(opts.host)
    redis_password = CONFIG[opts.host]['password']
  end
end

r = Redis.new(host: opts.host, port: opts.port, password: redis_password)
begin
  r.ping()
rescue Redis::CannotConnectError
  error("redis is not connecting")
rescue  Redis::CommandError
  error("redis password error")
end

time = Time.now

event = {
  time: time.to_s,
  elapsed: 0,
  host: Socket.gethostname,
  command: 'sheepdog_ping.rb',
  tag: opts.tag,
  stdout: "",
  stderr: error_msg,
  status: errval
}

id = 'sheepdog:'+opts.channel

if errval != 0
  event[:err] = "FAIL"
else
  event[:err] = "SUCCESS"
end

if opts.always or errval != 0
  if verbose
    puts(event)
    puts("Pushing out an event (#{id})\n")
  end
  json = event.to_json
  r.sadd(id,json)
  if opts.log
    File.open(opts.log,"a") { |f| f.print(json,",\n") }
  end
else
  puts("No event to report (#{id})") if verbose
end
