# file operations

require 'fileutils'

module Deploy
  module FileOps

    def FileOps.copy_file(source,dest)
      p ["copy_file",source,dest]
      if File.directory?(dest)
        dest = dest + '/' + File.basename(source)
      end
      # p File.stat(dest).mode.to_s(2)
      # p 0222.to_s(2)
      if (File.exist?(dest) and (File.stat(dest).mode & 0222))
        chmod(dest,0600)  # until we have checking in place, override mode for writing
      end
      FileUtils.copy_file(source,dest)
      dest
    end

    def FileOps.copy_recursive(source,destdir)
      # Using a system copy here because we don't want the added
      # source directory
      print `cp -vau #{source+'/*'} #{destdir}`
    end
    
    def FileOps.chmod(item,mode=0755)
      p [item,mode.to_s(8)]
      if mode.to_s(8) != (File.stat(item).mode).to_s(8)[-3..-1]
        p ["chmod",mode.to_s(8)]
        File.chmod(mode,item)
      end
    end

    # Makes dir and returns the created directory
    def FileOps.mkdir(dir,mode=0755)
      p [dir,mode]
      if not File.directory?(dir)
        p ["mkdir",dir,mode.to_s(8)]
        Dir.mkdir(dir,mode)
      else
        FileOps.chmod(dir,mode)
      end
      dir
    end

  end
end

