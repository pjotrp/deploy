#! /usr/bin/env ruby
#
# sheepdog_list prints the queue
#

rootpath = File.dirname(File.dirname(__FILE__))
$: << File.join(rootpath,'lib')

require 'json'
require 'optparse'
require 'ostruct'
require 'sheepdog'
require 'colorize'

options = {
  channel: 'run',
  host: 'localhost',
  port: 6379 # redis port
}

opts = get_options(opts,options, lambda { |opts,options|
                     opts.on("--[no-]json", "Output valid JSON") do |json|
                       options[:json] = json
                     end
                     opts.on("--status", "Output status") do |status|
                       options[:status] = status
                     end
                     opts.on("--failed", "Show records matching FAIL") do |b|
                       options[:failed] = b
                     end
                     opts.on("--filter regex", "Show records matching regex") do |regex|
                       options[:filter] = regex
                     end
                   })
verbose = options[:verbose]
filter = options[:filter]
filter ||= options[:tag]

r = redis_connect(opts)

channel = "sheepdog:"+opts.channel

status = {}

print("[") if opts.json
r.smembers(channel).sort.each_with_index do | buf,i |
  begin
    event = JSON::parse(buf)
    e = OpenStruct.new(event)
  rescue JSON::ParserError
    next
  end
  tag = if e.tag
          e.tag
        else
          e.command
        end
  status[tag] = {time: e.time, host: e.host, status: e.err}
  if e.elapsed
    min = sprintf("%.2d",e.elapsed/60)
    sec = sprintf("%.2d",e.elapsed % 60)
  end
  next if options.has_key?(:failed) and e.err != "FAIL"
  next if filter and (e.tag !~ /#{filter}/ and e.host !~ /#{filter}/)
  if opts.json
    print(",") if i>0
    print(buf)
  elsif opts.status
  # skip
  elsif opts.filter
    event.delete("stderr")
    event.delete("stdout")
    if opts.full_output
      print(e.stdout.blue,"\n") if e.stdout
      print(e.stderr.red,"\n") if e.stderr
    else
      lines = e.stderr.split("\n")
      if lines.length > 3
        lines = lines.slice(-3,3)
      end
      print(lines.join("\n").red)
    end
    print(event.to_s.green,"\n")
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

if opts.status
  list = []
  status.each_pair { |e|
    k,v = e
    v['tag'] = k
    list.push(v)
  }
  print(list.to_json)
end
