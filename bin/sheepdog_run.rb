#! /usr/bin/env ruby
#
# sheepdog_run executes a command and sends its result into a
# monitoring queue. This runner is typically used in scripts or to
# wrap CRON jobs. It will send a message into a redis 'queue', e.g.
# on failure.
#
# To view members you can run redis-cli with
#
#   redis-cli LRANGE sheepdog_run 0 -1
#
# or use sheepdog_list.rb

rootpath = File.dirname(File.dirname(__FILE__))
$: << File.join(rootpath,'lib')

require 'sheepdog'

options = {
  cmd: 'echo "Hello world"',
  channel: 'run',
  host: 'localhost',
  port: 6379 # redis port
}

opts = get_options(opts,options, lambda { |opts,options|
                     opts.on("-c", "--cmd full", "Run command") do |cmd|
                       options[:cmd] = cmd
                     end
                   })

r = redis_connect(opts)

event = run(opts.tag,opts.cmd,opts.store_stdout,opts.verbose)

redis_report(r,event,opts)
