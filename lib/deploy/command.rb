require 'yaml'
require 'deploy/bag'

module Deploy

  module Command

    # This is the exec function for one module (YAML file). All
    # actions are put into a bag. Note that it acts in a closure. So
    # the last dir is shared in file.
    #
    # Returns a bag
    
    def Command.exec(fn,rundir,state)

      print "Run "+File.basename(fn)+" configuration\n"
      list = YAML.load(File.read(fn))
      p list
      bag = Bag.new(fn,state)

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
        if not File.exist?(source)
          source = masterfiles
        end
        source
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
                src = if opts and opts['source']
                        opts['source']
                      else
                        masterfiles
                      end
                FileOps.copy_recursive(mkmaster_path.call(src),destdir)
              end
            end
          when 'copy-file' then
            items.each do |item,opts|
              bag.copy_file(mkmaster_path.call(item),opts)
            end
          else
            raise "UNKNOWN COMMAND "+command
          end
        end
      end
      bag
    end

  end

end
