module Deploy

  module Execute

    def Execute.bag bag
      bag.each do | item |
        command,fn,opts = item
        p [command,fn,opts]
        case command
        when :mkdir then
          FileOps.mkdir(fn,opts[:mode])
        when :copy_recursive then
          FileOps.copy_recursive(opts[:source],fn)
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
