# A bag is a collection of module based commands or actions on
# files. A bag consists of a list of destination files with
# attributes, class and commands. This module contains some helper
# functions.

module Deploy

  class Bag

    attr_accessor :list
    def initialize(name,masterfiles,state)
      @name = name
      @state = state
      @masterfiles = masterfiles
      @list = []
      @destdir = nil
    end

    def each
      list.each do | item |
        yield item
      end
    end

    def dir item,opts
      mode = if opts and opts['mode']
               opts['mode'].to_i(8)
             else
               0755
             end
      nopts = {}
      nopts[:parameters] = opts
      nopts[:mode] = mode
      dir = @state.abspath(item)
      list.push [:mkdir,dir,nopts]
      @destdir = dir # cache last dir
      if opts and opts['recursive']
        p [item,opts]
        src = if opts and opts['source']
                opts['source']
              else
                @masterfiles
              end
        nopts = {}
        nopts[:parameters] = opts
        nopts[:source] = mkmaster_path(src)
        list.push [:copy_recursive,dir,nopts]
      end
      list
    end

    def copy_file item,opts
      mode = 0644 # default
      mode = opts['mode'].to_i(8) if opts and opts['mode']
      dest =
        if opts and opts['dest']
          opts['dest']
        else
          @destdir
        end
      # destination can be a file or directory
      # if it is not absolute, make it relative to $HOME
      if dest[0] != "/"
        dest = @state.homedir + '/' + dest
      end
      nopts = {}
      nopts[:parameters] = opts
      nopts[:source] = mkmaster_path(item)
      nopts[:mode] = mode
      list.push [:copy_file,dest,nopts]
      list
    end        

    def edit_file item,opts
      dest =
        if opts and opts['dest']
          opts['dest']
        else
          @destdir
        end
      # destination can be a file or directory
      # if it is not absolute, make it relative to $HOME
      if dest[0] != "/"
        dest = @state.homedir + '/' + dest
      end
      nopts = {}
      nopts[:parameters] = opts
      nopts[:source] = mkmaster_path(item)
      list.push [:edit_file,dest,nopts]
      list
    end        

    private
      
    def mkmaster_path(name)
      # source is a masterfile
      source = name
      if not File.exist?(source)
        source = @masterfiles+'/'+name
      end
      if not File.exist?(source)
        source = @masterfiles
      end
      source
    end

  end


end
