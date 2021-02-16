require 'json'
require 'redis'
require 'colorize'

HOME=ENV['HOME']
DEFAULT_CONFIGFN = HOME+"/.config/sheepdog/sheepdog.conf"

CONFIGFN = if File.exist?(DEFAULT_CONFIGFN)
             DEFAULT_CONFIGFN
           else
             HOME+"/.redis.conf"
           end
CONFIG = if File.exist?(CONFIGFN)
           JSON.parse(File.read(CONFIGFN))
         end
# CONFIG['HOME'] = HOME

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
  redis_ping(r)
  r
end

def redis_ping(r)
  begin
    r.ping()
  rescue Redis::CannotConnectError
    error("redis is not connecting")
  rescue  Redis::CommandError
    error("redis password error")
  rescue Redis::ConnectionError
    error("redis connection error")
  end
  true
end

def redis_report(r,event,opts, filter = nil)
  select = lambda do |buf|
    lines = buf.split("\n")
    if lines.length > 5
      lines = filter.call(lines) if filter
      if not opts[:full_output]
        lines = [[lines.slice(0,2),"(...)"]+lines.slice(-3,3)]
      end
    end
    lines.join("\n")
  end
  channel = "sheepdog:"+opts.channel
  id = channel
  verbose = opts[:verbose]

  if opts.always or event[:status] != 0
    if verbose
      event2 = event.dup
      event2[:stdout] = nil
      event2[:stderr] = nil
      print(select.call(event[:stdout]).blue,"\n")
      print(select.call(event[:stderr]).red,"\n")
      print(event2.to_s.green,"\n")
      puts("Pushing out event <#{id}> to <#{opts.host}>\n".green)
    end
    json = event.to_json
    r.sadd(id,json)
    if opts.log
      File.open(opts.log,"a") { |f| f.print(json,",\n") }
    end
  else
    puts("No event to report <#{id}>".green) if verbose
  end
end
