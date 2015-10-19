# file operations

require 'fileutils'

module Deploy
  module FileOps
    
    def FileOps.copy_file(source,dest)
      if File.directory?(dest)
        dest = dest + '/' + File.basename(source)
      end
      # p File.stat(dest).mode.to_s(2)
      # p 0222.to_s(2)
      if not Checksum.file_equal?(source,dest)
        if (File.exist?(dest) and (File.stat(dest).mode & 0222))
          chmod(dest,0600)  # until we have checking in place, override mode for writing
        end
        p ["Action: copying file",source,dest]
        FileUtils.copy_file(source,dest)
      else
        print "Skip: File #{dest} unchanged\n"
      end
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
    
    def FileOps.chmod(item,mode=0755)
      if mode.to_s(8) != (File.stat(item).mode).to_s(8)[-3..-1]
        print "Action: chmod #{itme} to ",mode.to_s(8),"\n"
        File.chmod(mode,item)
      else
        print "Skip: Mode 0#{mode.to_s(8)} for #{item} unchanged\n"
      end
    end

    # Makes dir and returns the created directory
    def FileOps.mkdir(dir,mode=0755)
      if not File.directory?(dir)
        p ["mkdir",dir,mode.to_s(8)]
        Dir.mkdir(dir,mode)
      else
        print "Skip: Directory #{dir} already exists\n"
        FileOps.chmod(dir,mode)
      end
      dir
    end

  end
end

