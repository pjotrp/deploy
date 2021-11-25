# Locking module for gemma (wrapper)
#

=begin

The logic is as follows:

1. a program creates a named lock file (based on a hash of its inputs) with its PID
2. on exit it destroys the file
3. a new program checks for the lock file
4. if it exists and the PID is still in the ps table - wait
5. when the pid disappears or the lock file - continue
6. a timeout will return an error in 3 minutes

Note that there is a theoretical chance the lock file existed, but disappeared. I think I have it covered by ignoring the unlink errors. Also the use of /proc/PID is Linux specific.

=end


require 'timeout'

module Lock

  def self.local name
    ENV['HOME']+"/."+name.gsub("/","-")+".lck"
  end

  def self.lock_pid name
    lockfn = local(name)
    if File.exist?(lockfn)
      File.read(lockfn).to_i
    else
      0
    end
  end

  def self.locked? name
    lockfn = local(name)
    pid = lock_pid(name)
    if File.exist?("/proc/#{pid}")
      true
    else
      # the program went away - remove any 'stale' lock
      begin
        File.unlink(lockfn)
      rescue Errno::ENOENT
        # ignore error when the lock file went missing
      end
      false # --> no longer locked
    end
  end

  def Lock::create name
    return false if not wait_for(name)
    lockfn = local(name)
    if File.exist?(lockfn)
      $stderr.print "\nERROR: Can not steal #{lockfn}"
      return false
    end
    File.open(lockfn, File::RDWR|File::CREAT, 0644) do |f|
      f.flock(File::LOCK_EX)
      f.print(Process.pid)
    end
    true
  end

  def Lock::wait_for name
    lockfn = local(name)
    begin
      status = Timeout::timeout(180) { # 3 minutes
        while locked?(name)
          $stderr.print("\nWaiting for lock #{lockfn}...")
          sleep 2
        end
      }
    rescue Timeout::Error
      $stderr.print "\nERROR: Timed out, but I can not steal #{lockfn}"
      return false
    end
    # yah! lock is released
    true
  end

  def Lock::release name
    lockfn = local(name)
    if Process.pid == lock_pid(name)
      begin
        File.unlink(lockfn) # PID expired
      rescue Errno::ENOENT
        # ignore error when the lock file went missing
      end
    else
      # $stderr.print "\nERROR: can not release #{lockfn} because it is not owned by me"
      # Ignore. Normally another process immediately grabs our lock - if there is contention
      # we will see above 'waiting for lock' messages
    end
  end

end
