require 'yaml'

module Deploy

  module Command

    # This is the exec function for one module (YAML file). Note that
    # it acts in a closure. So the last dir is shared in file.
    def Command.exec(fn,rundir,state)

      print "Run "+File.basename(fn)+" configuration\n"
      list = YAML.load(File.read(fn))
      p list
      destdir = nil
      masterfiles = rundir + '/masterfiles/' + File.basename(fn,'.yaml')
      if not File.directory?(masterfiles)
        masterfiles = rundir + '/masterfiles'
      end

      mkmaster_path = lambda { | name |
        # source is a masterfile
        source = name
        if not File.exist?(source)
          source = masterfiles+'/'+name
        end
        source
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
        newfn = FileOps.copy_file(mkmaster_path.call(item),dest)
        FileOps.chmod(newfn,mode)
      }

      list.each do | commands |
        commands.each do | command, items |
          p command
          case command 
          when 'dir' then
            items.each do |item,opts|
              mode = if opts and opts['mode']
                       opts['mode'].to_i(8)
                     else
                       0755
                     end
              destdir = FileOps.mkdir(state.abspath(item),mode)
              if opts and opts['recursive']
                FileOps.copy_recursive(mkmaster_path.call(opts['source']),destdir)
              end
            end
          when 'copy-file' then
            items.each do |item,opts|
              copy_file.call(item,opts)
            end
          else
            raise "UNKNOWN COMMAND "+command
          end
        end
      end
    end

  end

end
