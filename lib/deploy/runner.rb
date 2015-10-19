
require 'deploy/state'
require 'deploy/command'
require 'deploy/execute'

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
      bags = []
      Dir.glob(rundir+'/config/*.yaml').each do | fn |
        next if options[:module] and options[:module] != File.basename(fn,'.yaml')
        bag = Command.exec(fn,rundir,state)
        bags.push bag
        Execute.bag bag
      end
      state
    end
    
  end
end
