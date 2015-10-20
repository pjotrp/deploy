module Deploy

  module Execute

    def Execute.bag bag
      bag.each do | item |
        command,fn,opts = item
        p [command,fn,opts]
        case command
        when :mkdir then
          raise "HELL"
          # destdir = FileOps.mkdir(fn,opts[:mode])
        when :copy_recursive then
          raise "HELL"
          # FileOps.copy_recursive(fn,opts[:source])
        when :copy_file then
          newfn = FileOps.copy_file(opts[:source],fn)
          FileOps.chmod(newfn,opts[:mode])
        when :edit_file then
          raise "HELL"
          # newfn = FileOps.copy_file(opts[:source],fn)
          # FileOps.chmod(newfn,opts[:mode])
        else
          p item
          raise "Uknown bag command #{command}!"
        end
      end
      bag
    end
  end
end
