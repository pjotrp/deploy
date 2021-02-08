#! /usr/bin/env ruby
#
# sheepdog_borg runs a backup with borg.

require 'sheepdog'

options = {
  cmd: 'echo "Hello world"',
  channel: 'run',
  host: 'localhost',
  port: 6379 # redis port
}

opts = get_options(opts,options, lambda { |opts,options|
                     opts.on("-b", "--backup repo", "Backup directory") do |backup_repo|
                       options[:backup_repo] = backup_repo
                     end
                   })

r = redis_connect(opts)

event = run(opts.tag,opts.cmd)

redis_report(r,event,opts)
