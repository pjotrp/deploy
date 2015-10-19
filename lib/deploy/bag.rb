# A bag is a collection of commands or actions on files. A bag
# consists of a list of destination files with attributes, class and
# commands. This module contains some helper functions.

module Deploy

  class Bag

    attr_accessor :list
    def initialize(name,state)
      @name = name
      @state = state
      @list = []
    end

    def each
      list.each do | item |
        yield item
      end
    end
    
    def copy_file item,opts
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
        dest = @state.homedir + '/' + dest
      end
      nopts = {}
      nopts[:parameters] = opts
      nopts[:dest] = dest
      nopts[:mode] = mode
      list.push [:copy_file,item,nopts]
      list
    end        
  end


end
