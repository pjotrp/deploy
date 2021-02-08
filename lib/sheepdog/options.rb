
def get_options(opts, options, func = nil)
  OptionParser.new do |opts|
    opts.banner = "Usage: sheepdog_run.rg [options]"

    opts.on("-h", "--host name", "Attach to redis on host") do |host|
      options[:host] = host
    end
    opts.on("-p", "--port num", Integer, "Attach to redis on port") do |port|
      options[:port] = port
    end
    opts.on("--password str", "Attach to redis with password") do |pwd|
      redis_password = pwd
    end
    opts.on("-t", "--tag tag", "Set message tag") do |tag|
      options[:tag] = 'PING '+tag
    end
    opts.on("--log [file]", "Also log output to file (default sheepdog.log)") do |log|
      log = "sheepdog.log" if not log
      options[:log] = log
    end
    opts.on("-v", "--[no-]verbose", "Run verbosely (--no-verbose is quiet mode)") do |v|
      options[:verbose] = v
    end

    func.call(opts,options) if func

  end.parse!


  p options if options[:verbose]

  OpenStruct.new(options)
end
