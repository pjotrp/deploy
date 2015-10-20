module Deploy

  module Execute

    def Execute.bag bag
      bag.each do | item |
        command,dest,opts = item
        p [command,dest,opts]
        case command
        when :mkdir then
          FileOps.mkdir(dest,opts[:mode])
        when :copy_recursive then
          FileOps.copy_recursive(opts[:source],dest)
        when :copy_file then
          FileOps.copy_file(opts[:source],dest)
        when :edit_file then
          FileOps.edit_file(opts[:source],dest,opts[:edit_lines])
        else
          p item
          raise "Uknown bag command #{command}!"
        end
      end
      bag
    end
  end
end
