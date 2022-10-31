#! /usr/bin/env ruby
#
# sheepdog_check_storage checks local storage
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
                   })
verbose = options[:verbose]

r = redis_connect(opts)

channel = "sheepdog_"+opts.channel

tag = 'disk-storage' if not tag

cmd = 'df -h'
stdout, stderr, status = Open3.capture3(cmd)
status = status.exitstatus

if status==0
  buf = stdout.split("\n")
  header = buf[0].split(/\s+/)
  perc = header[4]
  if perc =~ /%/
    buf.each do |line|
      dev,size,use,free,perc,path = line.split(/\s+/)
      if perc.to_i >= 90
        tag += ' '+path+":"+perc
        status = 2
      end
    end
  end
end

if status>0
  event = {
    time: Time.now().to_s,
    elapsed: 0,
    user: ENV['USER'],
    host: Socket.gethostname,
    command: "sheepdog_check_storage.rb",
    tag: tag,
    stdout: "",
    stderr: stdout + stderr,
    err: "WARNING",
    status: status
  }
  redis_report(r,event,opts)
end

exit status
