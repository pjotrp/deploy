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

require 'open3'
require 'optparse'
require 'ostruct'
require 'redis'
require 'socket'

def error(msg)
  print("ERROR: "+msg+" (sheepdog)\n")
  exit(1)
end

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
  opts.on("-p", "--port num", Integer, "Run local redis on port") do |port|
    options[:port] = port
  end
  opts.on("-t", "--tag tag", "Set message tag") do |tag|
    options[:tag] = tag
  end
  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end

end.parse!

verbose = options[:verbose]
p options if verbose

opts = OpenStruct.new(options)

r = Redis.new(host: opts.host, port: opts.port)
begin
  r.get("just testing@")
rescue Redis::CannotConnectError
  error("redis is not connecting")
end
channel = "sheepdog:"+opts.channel

begin
  stdout, stderr, status = Open3.capture3(opts.cmd)
  errval = status.exitstatus
rescue Errno::ENOENT
  stderr = "Command not found"
  err    = "CMD_NOT_FOUND"
  errval = 1
end

time = Time.now
# timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
timestamp = time.to_i

event = {
  time: time.to_s,
  host: Socket.gethostname,
  command: opts.cmd,
  tag: opts.tag,
  stdout: stdout,
  stderr: stderr,
  status: errval
}

id = channel

p id,event if verbose

if errval != 0
  if verbose
    puts(stderr)
    puts("Pushing out an event (sheepdog)\n")
  end
  event[:err] = "FAIL"
  r.sadd(id,event)
else
  puts("No event to report (sheepdog)") if verbose
end
