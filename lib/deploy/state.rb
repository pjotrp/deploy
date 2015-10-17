
require 'deploy/host'

module Deploy

  class State

    attr_reader :hostname, :username, :homedir
    
    def initialize
      @hostname = Host.hostname()
      @username = Host.username()
      @homedir  = Host.homedir()
    end

    # if it is not absolute, make it relative to $HOME
    def abspath path
      if path[0] != '/'
        @homedir + '/' + path
      else
        path
      end
    end
    
  end
end
