require 'colorize'

def error(msg)
  print("ERROR: #{msg} (sheepdog)\n".red)
  exit(1)
end
