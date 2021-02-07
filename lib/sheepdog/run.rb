require 'open3'

def run(tag,cmd)
  starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)

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
    host: Socket.gethostname,
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
