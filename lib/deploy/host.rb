
module Deploy

  module Host

    def Host.hostname
      `cat /etc/hostname`.strip
    end
    
    def Host.username
      ENV['USER']
    end
    
    def Host.homedir
      ENV['HOME']
    end

  end
end
