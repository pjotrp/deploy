
require 'deploy/state'
require 'deploy/command'

module Deploy

  module Runner

    def self.run options, rundir
      p options,rundir
      # Fetch machine state
      state = State.new
      p state
      # Fetch classes

      # Now run the files in $rundir/config
      Dir.glob(rundir+'/config/*.yaml').each do | fn |
        Command.exec(fn,rundir,state)
      end 
      state
    end
    
  end
end
