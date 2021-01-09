#! /usr/bin/env ruby
#
# sheepdog_run executes a command and sends its result into a
# monitoring queue. This runner is typically used in scripts or to
# wrap CRON jobs.

require 'open3'
require 'optparse'
require 'ostruct'

options = {
  cmd: 'echo "Hello world"'
}
OptionParser.new do |opts|
  opts.banner = "Usage: sheepdog_run.rg [options]"

  opts.on("-c", "--cmd full", "Run command") do |cmd|
    options[:cmd] = cmd
  end
  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end

end.parse!

p options if options[:verbose]

opts = OpenStruct.new(options)

stdout, stderr, status = Open3.capture3(opts.cmd)

if status != 0
  print(stderr)
end
