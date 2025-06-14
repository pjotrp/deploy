require 'json'
require 'redis'
require 'colorize'
require 'sheepdog/options'
require 'sheepdog/email'

def redis_connect(opts)
  r = Redis.new(host: opts.host, port: opts.port, password: opts.password)
  return nil if not redis_ping(r,opts)
  r
end

def redis_ping(r,host)
  begin
    r.ping()
  rescue Redis::TimeoutError
    warning("redis on #{host} is timing out")
    return false
  rescue Redis::CannotConnectError
    warning("redis on #{host} is not connecting")
    return false
  rescue  Redis::CommandError
    warning("redis on #{host} password error")
    return false
  rescue Redis::ConnectionError
    warning("redis on #{host} connection error")
    return false
  rescue
    warning("redis on #{host} unknown error")
    return false
  end
  true
end

def redis_report(r, event, opts, filter = nil)
  verbose = opts[:verbose]
  select = lambda do |buf|
    if buf
      lines = buf.split("\n")
      if lines.length > 5
        lines = filter.call(lines) if filter
        if not opts[:full_output]
          lines = [[lines.slice(0,2),"(...)"]+lines.slice(-3,3)]
        end
      end
      lines.join("\n")
    else
      ""
    end
  end
  channel = "sheepdog_"+opts.channel
  id = channel

  if opts.always or event[:status] != 0
    if verbose
      event2 = event.dup
      event2[:stdout] = nil
      event2[:stderr] = nil
      print(select.call(event[:stdout]).blue,"\n")
      print(select.call(event[:stderr]).red,"\n")
      print(event2.to_s.green,"\n")
      puts("Pushing out event <#{id}> to <#{opts.host}:#{opts.port}>\n".green)
    end
    event[:stdout] = nil if (not opts.store_stdout) # reduce noise
    json = event.to_json
    if r == nil
      puts("redis: can not write event to queue".green)
      return
    else
      r.lpush(id,json)
    end
    if opts.log
      File.open(opts.log,"a") { |f| f.print(json,",\n") }
    end
  else
    puts("No event to report <#{id}>".green) if verbose
  end
  if opts.email and event[:status] != 0
    puts("Sending E-mail to #{opts.email}".green)
    msg = "Subject: sheepdog failed!\n\n"+json+"\n"
    send_mail(opts.email,msg)
  end
  if event[:status] != 0
    puts("Bailing out <#{id}>".red) if verbose
    exit 1
  end
end
