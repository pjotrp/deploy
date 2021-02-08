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

opts = get_options(opts,options, lambda { |opts,options|
                     opts.on("-t", "--tag tag", "Set message tag") do |tag|
                       options[:tag] = 'PING '+tag
                     end
                   })

r = redis_connect(opts)

event = sheepdog_ping(opts.tag,r)

redis_report(r,event,opts)
