require 'json'
require 'redis'

CONFIG = nil

# Read options file
CONFIGFN = ENV['HOME']+"/.redis.conf"
if File.exist?(CONFIGFN)
  CONFIG = JSON.parse(File.read(ENV['HOME']+"/.redis.conf"))
end

def redis_get_password(opts)
  redis_password = nil
  if CONFIG and opts.host and not redis_password
    if CONFIG.has_key?(opts.host)
      redis_password = CONFIG[opts.host]['password']
    end
  end
  redis_password
end

def redis_connect(opts)
  redis_password = redis_get_password(opts)
  r = Redis.new(host: opts.host, port: opts.port, password: redis_password)
  begin
    r.ping()
  rescue Redis::CannotConnectError
    error("redis is not connecting")
  rescue  Redis::CommandError
    error("redis password error")
  rescue Redis::ConnectionError
    error("redis connection error")
  end
  r
end

def report(r,event,opts)
  channel = "sheepdog:"+opts.channel
  id = channel
  verbose = opts[:verbose]

  if opts.always or event[:status] != 0
    if verbose
      puts(event)
      puts("Pushing out an event (#{id})\n")
    end
    json = event.to_json
    r.sadd(id,json)
    if opts.log
      File.open(opts.log,"a") { |f| f.print(json,",\n") }
    end
  else
    puts("No event to report (#{id})") if verbose
  end
end
