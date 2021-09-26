require 'colorize'

def warning(msg)
  print("WARNING: #{msg} (sheepdog)\n".red)
end

def error(msg)
  print("ERROR: #{msg} (sheepdog)\n".red)
  exit(1)
end
