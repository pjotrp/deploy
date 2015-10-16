require 'yaml'

module Deploy

  module Command

    # This is the exec function for one module (YAML file). Note that
    # it acts in a closure. So the last dir is shared in file.
    def Command.exec(fn)
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
                if mode.to_s(8) != (File.stat(item).mode).to_s(8)[-3..-1]
                  p ["chmod",mode.to_s(8)]
                  File.chmod(mode,item)
                end
              end
              dir = item
            end
          when 'file' then
            items.each do |item,opts|
              p [item,opts]
            end
          else
            raise "UNKNOWN COMMAND "+command
          end
        end
      end
    end

  end

end
