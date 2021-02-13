#! /usr/bin/env ruby
#
# sheepdog_expect checks for a last connection using regex, e.g.
#
#   sheepdog_expect --filter penguin2 --elapse 24h
#

rootpath = File.dirname(File.dirname(__FILE__))
$: << File.join(rootpath,'lib')

require 'json'
require 'optparse'
require 'ostruct'
require 'sheepdog'
require 'time'
require 'colorize'

options = {
  channel: 'run',
  host: 'localhost',
  port: 6379 # redis port
}

opts = get_options(opts,options, lambda { |opts,options|
                     opts.on("--filter regex", "Show records matching regex") do |regex|
                       options[:filter] = regex
                     end
                     opts.on("--elapse time", "Elapsed time (default 24h)") do |t|
                       options[:elapse] = t
                     end
                   })
verbose = options[:verbose]
filter = options[:filter]
e = options[:elapse]
elapse =
  if e =~ /(\d+)h/
    $1.to_i * 3600
  elsif e =~ /(\d+)m/
    $1.to_i * 60
  else
    24*3600
  end

r = redis_connect(opts)

channel = "sheepdog:"+opts.channel

status = 1

checktime = Time.now - elapse
r.smembers(channel).sort.each_with_index do | buf,i |
  begin
    event = JSON::parse(buf)
    e = OpenStruct.new(event)
  rescue JSON::ParserError
    next
  end
  next if filter and (e.tag !~ /#{filter}/ and e.host !~ /#{filter}/)
  time = Time.parse(e.time).to_i
  if checktime.to_i < time
    p [e.time,e.host,e.tag,e.err] if verbose
    status = 0
  end
end

exit status
