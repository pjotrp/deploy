require 'yaml'

module Deploy

  module Command

    # This is the exec function for one module (YAML file). Note that
    # it acts in a closure. So the last dir is shared in file.
    def Command.exec(fn,rundir,state)

      print "Run "+fn+"\n"
      list = YAML.load(File.read(fn))
      p list
      destdir = nil
      masterfiles = rundir + '/masterfiles/' + File.basename(fn,'.yaml')
      if not File.directory?(masterfiles)
        masterfiles = rundir + '/masterfiles'
      end

      mkdir = lambda { |item,opts|
        p [item,opts]
        mode = 0755 # default
        mode = opts['mode'].to_i(8) if opts and opts['mode']
        # if it is not absolute, make it relative to $HOME
        dest = item
        if dest[0] != '/'
          dest = state.homedir + '/' + item
        end
        p ['mkdir?',dest]
        if not File.directory?(dest)
          p ["mkdir",dest,mode.to_s(8)]
          Dir.mkdir(dest,mode)
        else
          FileOps.chmod(dest,mode)
        end
        dest
      }

      copy_file = lambda { |item,opts| 
        p [item,opts]
        mode = 0644 # default
        mode = opts['mode'].to_i(8) if opts and opts['mode']
        dest =
          if opts and opts['dest']
            opts['dest']
          else
            destdir
          end
        # destination can be a file or directory
        # if it is not absolute, make it relative to $HOME
        if dest[0] != "/"
          dest = state.homedir + '/' + dest
        end
        p [:destx,dest]
        p [:itemx,item]
        # source is a masterfile
        source = item
        if not File.exist?(item)
          source = masterfiles+'/'+item
        end
        newfn = FileOps.copy_file(source,dest)
        FileOps.chmod(newfn,mode)
      }
      
      list.each do | commands |
        commands.each do | command, items |
          p command
          case command 
          when 'dir' then
            items.each do |item,opts|
              destdir = mkdir.call(item,opts)
            end
          when 'file' then
            items.each do |item,opts|
              copy_file.call(item,opts)
            end
          when 'files' then
            items.each do |glob,opts|
              p [glob,opts]
              source = masterfiles
              if opts and opts['source']
                source = rundir + '/' + opts['source']
              end
              globbing = source + '/' + glob
              p [:globbing,globbing]
              Dir.glob(globbing) do |item|
                p ['item',item]
                dest = item[source.size+1..-1]
                dest = destdir + '/' + dest
                p ['dest',dest]
                if File.directory?(item)
                  destdir = mkdir.call(dest,opts)
                else
                  copy_file.call(item,opts)
                end
              end
            end
          else
            raise "UNKNOWN COMMAND "+command
          end
        end
      end
    end

  end

end
