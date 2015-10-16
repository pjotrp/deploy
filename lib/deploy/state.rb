
require 'deploy/host'

module Deploy

  class State

    attr_reader :hostname, :username, :homedir
    
    def initialize
      @hostname = Host.hostname()
      @username = Host.username()
      @homedir  = Host.homedir()
    end
    
  end
end
