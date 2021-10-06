require 'open3'
require 'colorize'

def sheepdog_ping(tag,r)
  ok = redis_ping(r)

  errval = !ok
  event = {
    time: Time.new.to_s,
    elapsed: 0,
    host: Socket.gethostname, # sending host
    command: 'sheepdog_ping.rb',
    tag: tag,
    stdout: "",
    stderr: "",
    status: 0,
    err: "SUCCESS"
  }
  event
end

def run(tag, cmd, verbose=false)
  starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)

  print(cmd.green+"\n") if verbose
  begin
    stdout, stderr, status = Open3.capture3(cmd)
    errval = status.exitstatus
  rescue Errno::ENOENT
    stderr = "Command not found"
    err    = "CMD_NOT_FOUND"
    errval = 1
  end

  ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  elapsed = ending - starting

  time = Time.now
  # timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
  timestamp = time.to_i

  event = {
    time: time.to_s,
    elapsed: elapsed.round(),
    host: Socket.gethostname, # sending host
    command: cmd,
    tag: tag,
    stdout: stdout,
    stderr: stderr,
    status: errval
  }

  if errval != 0
    event[:err] = "FAIL"
  else
    event[:err] = "SUCCESS"
  end

  event
end
