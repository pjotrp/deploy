
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
      if not File.directory?(rundir)
        raise "Rundir is missing #{rundir}"
      end

      # Now run the files in $rundir/config
      Dir.glob(rundir+'/config/*.yaml').each do | fn |
        next if options[:module] and options[:module] != File.basename(fn,'.yaml')
        Command.exec(fn,rundir,state)
      end 
      state
    end
    
  end
end
