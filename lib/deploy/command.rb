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

      destdir = nil
      masterfiles = rundir + '/masterfiles/' + File.basename(fn,'.yaml')
      if not File.directory?(masterfiles)
        masterfiles = rundir + '/masterfiles'
      end

      bag = Bag.new(fn,masterfiles,state)

      list.each do | commands |
        commands.each do | command, items |
          case command
          when 'dir' then
            items.each do |item,opts|
              bag.dir(item,opts)
            end
          when 'copy-file' then
            items.each do |item,opts|
              bag.copy_file(item,opts)
            end
          when 'edit-file' then
            items.each do |item,opts|
              bag.edit_file(item,opts)
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
