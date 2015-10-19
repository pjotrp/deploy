module Deploy

  module Execute

    def Execute.bag bag
      bag.each do | item |
        command,fn,opts = item
        case command
        when :copy_file then
          p [command,fn,opts]
          newfn = FileOps.copy_file(opts[:source],fn)
          FileOps.chmod(newfn,opts[:mode])
        when :mkdir then
          # destdir = FileOps.mkdir(fn,opts[:mode])
        when :copy_recursive then
          p item
          # FileOps.copy_recursive(fn,opts[:source])
        else
          p item
          raise "Uknown bag command #{command}!"
        end
      end
      bag
    end
  end
end
