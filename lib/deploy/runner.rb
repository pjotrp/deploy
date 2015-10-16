
require 'deploy/state'

module Deploy

  module Runner

    def self.run options, rundir
      p options,rundir
      state = State.new
      p state
      state
    end
    
  end
end
