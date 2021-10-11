#! /usr/bin/env ruby
#
#
# rsync -va /var/services/homes/pjotr/mnt/ /volume1/common/backup/machines/tux01/

rootpath = File.dirname(File.dirname(__FILE__))
$: << File.join(rootpath,'lib')

require 'sheepdog'
require 'time'

options = {
  cmd: 'rsync',
  tag: 'RSYNC',
  channel: 'run',
  host: 'localhost',
  port: 6379 # redis port
}

opts = get_options(opts,options, lambda { |opts,options|
                     opts.on("--bin rsync", "Binary to run (default rsync)") do |bin|
                       options[:cmd] = bin
                     end
                     opts.on("--args rsync-args", "Extra arguments - e.g. --stats") do |a|
                       options[:args] = a
                     end
                     opts.on("--lock-borg", "Use borg with-lock") do |b|
                       options[:lock_borg] = true
                     end
                   })

files = ARGV
destdir = files.pop

r = redis_connect(opts)

borg_passphrase = ENV['BORG_PASSPHRASE']

stamp = Time.now.strftime("%Y%m%d-%H:%M-%a")

cmd = "rsync -rt"
cmd += " "+options[:args] if options[:args]
cmd += " "+files.join(" ")+" "+destdir

cmd = "borg with-lock "+cmd if options[:lock_borg]

event = run(options[:tag],cmd,options[:verbose])

if event[:err] == "SUCCESS"
  if event[:stdout] =~ /total size is 0/
    event[:err] = "CHECK"
  end
end

redis_report(r,event,opts)
