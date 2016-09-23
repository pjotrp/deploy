# file operations

require 'fileutils'

module Deploy
  module FileOps

    # Makes dir and returns the created directory
    def FileOps.mkdir(dir,mode=nil)
      mode = 0555 if not mode
      if not File.directory?(dir)
        p ["mkdir",dir,mode.to_s(8)]
        Dir.mkdir(dir,mode)
      else
        print "Skip: Directory #{dir} already exists\n"
        FileOps.chmod(dir,mode)
      end
      dir
    end

    def FileOps.copy_file(source,dest,mode=nil)
      # p File.stat(dest).mode.to_s(2)
      # p 0222.to_s(2)
      if not Checksum.file_equal?(source,dest)
        override_readonly(dest) {
          p ["Action: copying file",source,dest]
          FileUtils.copy_file(source,dest)
        }
      else
        print "Skip: File #{dest} unchanged\n"
      end
      FileOps.chmod(dest,mode)
      dest
    end

    # Fixme: copy_recursive should use SHA values
    def FileOps.copy_recursive(source,destdir)
      # Using a system copy here because we don't want the added
      # source directory
      print "Action: copy-recursive from #{source} to #{destdir}\n"
      raise "Source does not exist #{source}" if not File.directory?(source)
      raise "Destination does not exist #{destdir}" if not File.directory?(destdir)
      print `cp -urP #{source+'/*'} #{destdir}`
    end

    # Returns the used mode
    def FileOps.chmod(item,mode=nil)
      mode = 0444 if not mode # default
      if mode.to_s(8) != (File.stat(item).mode).to_s(8)[-3..-1]
        print "Action: chmod #{item} to ",mode.to_s(8),"\n"
        File.chmod(mode,item)
      else
        print "Skip: Mode 0#{mode.to_s(8)} for #{item} unchanged\n"
      end
      mode
    end

    def FileOps.edit_file(source,dest,edit_lines)
      # For now edit file in place
      oldbuf = nbuf = File.read(dest).split(/\n/)
      edit_lines.each do | edit |
        if edit['replace']
          regex = edit['replace']
          with = edit['with']
          # print "#{regex}\n"
          nbuf = nbuf.map { | line |
            if eval("line =~ #{regex}")
              p [:replace,line,with]
              with
            else
              line
            end
          }
          next
        end
        if edit['append-unique']
          append = edit['append-unique']
          found = false
          nbuf.each do | line |
            if line == append
              found = true
              break
            end
          end
          if not found
            p [:append,append]
            nbuf << append
          end
          next
        end
        p edit
        raise "Uknown edit command"
      end
      if oldbuf != nbuf
        override_readonly(dest) {
          File.write(dest,nbuf.join("\n"))
        }
      end
    end

    private

    def self.override_readonly fn, &block
      mode = nil
      if (File.exist?(fn) and (File.stat(fn).mode & 0400))
        mode = File.stat(fn).mode
        File.chmod(0600,fn)
      end
      block.call
      File.chmod(mode,fn) if mode
    end
  end
end
