require 'yaml'

module Deploy

  module Command

    # This is the exec function for one module (YAML file). Note that
    # it acts in a closure. So the last dir is shared in file.
    def Command.exec(fn,rundir)
      destdir = nil
      print "Run "+fn+"\n"
      list = YAML.load(File.read(fn))
      list.each do | commands |
        commands.each do | command, items |
          p command
          case command 
          when 'dir' then
            items.each do |item,opts|
              p [item,opts]
              mode = 0755 # default
              mode = opts['mode'].to_i(8) if opts['mode']
              if not File.directory?(item)
                p ["mkdir",item,mode.to_s(8)]
                Dir.mkdir(item,mode)
              else
                FileOps.chmod(item,mode)
              end
              destdir = item
            end
          when 'file' then
            items.each do |item,opts|
              p [item,opts]
              mode = 0644 # default
              mode = opts['mode'].to_i(8) if opts['mode']
              dest =
                if opts['dest']
                  opts['dest']
                else
                  destdir
                end
              # destination can be a file or directory
              source = rundir+'/masterfiles/'+item
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
