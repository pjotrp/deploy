require 'digest/sha1'

module Deploy
  module Checksum

    def Checksum.buffer buf
      Digest::SHA1.hexdigest buf
    end

    def Checksum.file fn
      Digest::SHA1.hexdigest File.read(fn)
    end

    # Returns a list of SHA values, skipping on regex
    def Checksum.files fns, skip = nil
      fns.map { |fn| Check.file(fn) }
    end

    def Checksum.file_equal?(fn1, fn2)
      return false if !File.exist?(fn2)
      Checksum.file(fn1) == Checksum.file(fn2)
    end
  end
end
