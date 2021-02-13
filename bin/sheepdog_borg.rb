#! /usr/bin/env ruby
#
# sheepdog_borg runs a backup with borg.

rootpath = File.dirname(File.dirname(__FILE__))
$: << File.join(rootpath,'lib')

require 'sheepdog'
require 'time'

options = {
  cmd: 'borg',
  tag: 'BORG',
  channel: 'run',
  host: 'localhost',
  port: 6379 # redis port
}

opts = get_options(opts,options, lambda { |opts,options|
                     opts.on("-b", "--backup repo", "Backup directory") do |backup_repo|
                       options[:backup_repo] = backup_repo
                     end
                     opts.on("--bin borg", "Binary to run") do |bin|
                       options[:cmd] = bin
                     end
                     opts.on("--args borg-args", "Extra arguments for borg - e.g. --stats") do |a|
                       options[:args] = a
                     end
                     opts.on("--init", "Initialize") do ||
                       options[:init] = true
                     end
                   })

dir = options[:backup_repo]
error("Missing --backup directory") if not dir
if Process.uid == 0
  if File.stat(dir).mode != 040700
    p File.stat(dir)
    error(dir+" has wrong permission! Set: chmod 0700 "+dir)
  end
end

r = redis_connect(opts)

borg_passphrase = ENV['BORG_PASSPHRASE']

BORG_CONFIGFN = ENV['HOME']+"/.borg-pass"
if File.exist?(BORG_CONFIGFN)
  if File.stat(BORG_CONFIGFN).mode != 0100400
    error(BORG_CONFIGFN+" has wrong permission! Set: chmod 0400 "+BORG_CONFIGFN)
  end
  line = File.read(BORG_CONFIGFN)
  borg_passphrase = line.split("=")[1].strip
end

error("BORG_PASSPHRASE not set") if not borg_passphrase

ENV['BORG_PASSPHRASE'] = borg_passphrase

stamp = Time.now.strftime("%Y%m%d-%H:%M-%a")


if not File.directory?(dir)
  cmd = "borg init --encryption=repokey-blake2 #{dir}"
  print(`#{cmd}`)
end

repo = dir+"::"+options[:tag]+"-"+stamp
cmd = "borg create \""+repo+"\" "+ARGV.join(" ")

cmd += " "+options[:args] if options[:args]
event = run(options[:tag],cmd,options[:verbose])

redis_report(r,event,opts)
