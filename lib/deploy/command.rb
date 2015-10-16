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
      list.each do | commands |
        commands.each do | command, items |
          p command
          case command 
          when 'dir' then
            items.each do |item,opts|
              p [item,opts]
              mode = 0755 # default
              mode = opts['mode'].to_i(8) if opts and opts['mode']
              # if it is not absolute, make it relative to $HOME
              dest = item
              if dest[0] != '/'
                dest = state.homedir + '/' + item
              end
              if not File.directory?(dest)
                p ["mkdir",dest,mode.to_s(8)]
                Dir.mkdir(dest,mode)
              else
                FileOps.chmod(dest,mode)
              end
              destdir = dest
            end
          when 'file' then
            items.each do |item,opts|
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
              if dest[0] != '/'
                dest = state.homedir + '/' + dest
              end
              # source is a masterfile
              source = masterfiles+'/'+item
              newfn = FileOps.copy_file(source,dest)
              FileOps.chmod(newfn,mode)
            end
          else
            raise "UNKNOWN COMMAND "+command
          end
        end
      end
    end

  end

end
