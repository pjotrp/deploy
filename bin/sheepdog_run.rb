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

require 'json'
require 'open3'
require 'optparse'
require 'ostruct'
require 'redis'
require 'socket'

def error(msg)
  print("ERROR: "+msg+" (sheepdog)\n")
  exit(1)
end

# Read options file
CONFIGFN = ENV['HOME']+"/.redis.conf"
if File.exist?(CONFIGFN)
  CONFIG = JSON.parse(File.read(ENV['HOME']+"/.redis.conf"))
end

redis_password = nil
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

verbose = options[:verbose]
p options if verbose

opts = OpenStruct.new(options)

if CONFIG and opts.host and not redis_password
  redis_password = CONFIG[opts.host]['password']
end

p redis_password

r = Redis.new(host: opts.host, port: opts.port, password: redis_password)
begin
  r.ping()
rescue Redis::CannotConnectError
  error("redis is not connecting")
rescue  Redis::CommandError
  error("redis password error")
end
channel = "sheepdog:"+opts.channel

starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)

begin
  stdout, stderr, status = Open3.capture3(opts.cmd)
  errval = status.exitstatus
rescue Errno::ENOENT
  stderr = "Command not found"
  err    = "CMD_NOT_FOUND"
  errval = 1
end

ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
elapsed = ending - starting

time = Time.now
# timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
timestamp = time.to_i

event = {
  time: time.to_s,
  elapsed: elapsed.round(),
  host: Socket.gethostname,
  command: opts.cmd,
  tag: opts.tag,
  stdout: stdout,
  stderr: stderr,
  status: errval
}

id = channel

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
