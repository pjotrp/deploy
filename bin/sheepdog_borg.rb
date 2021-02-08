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
                     opts.on("--init", "Initialize") do ||
                       options[:init] = true
                     end
                   })

r = redis_connect(opts)

borg_passphrase = ENV['BORG_PASSPHRASE']

BORG_CONFIGFN = ENV['HOME']+"/.borg-pass"
if File.exist?(BORG_CONFIGFN)
  line = File.read(BORG_CONFIGFN)
  borg_passphrase = line.split("=")[1].strip
end

error("BORG_PASSPHRASE not set") if not borg_passphrase

ENV['BORG_PASSPHRASE'] = borg_passphrase

stamp = Time.now.strftime("%Y%m%d-%H:%M-%a")

dir = options[:backup_repo]

if not File.directory?(dir)
  cmd = "borg init --encryption=repokey-blake2 #{dir}"
  print(`#{cmd}`)
end

repo = dir+"::"+options[:tag]+stamp
cmd = "borg create \""+repo+"\" "+ARGV.join(" ")

event = run(repo,cmd,options[:verbose])

redis_report(r,event,opts)
