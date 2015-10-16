
require 'deploy/state'
require 'deploy/command'

module Deploy

  module Runner

    def self.run options, rundir
      p options,rundir
      # Fetch machine state
      state = State.new
      p state
      Command.exec(rundir)
      state
    end
    
  end
end
