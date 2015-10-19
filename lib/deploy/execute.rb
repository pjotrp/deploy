module Deploy

  module Execute

    def Execute.bag bag
      bag.each do | item |
        command,fn,opts = item
        case command
        when :copy_file then
          p [command,fn,opts]
          newfn = FileOps.copy_file(fn,opts[:dest])
          FileOps.chmod(newfn,opts[:mode])
        end
      end
      bag
    end
  end
end
