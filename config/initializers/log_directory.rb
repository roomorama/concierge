# The application needs a +log+ directory to exist so that general logs can
# be created. However, instead of adding an empty +log+ directory to source
# control, we check whether the directory exists when the application is booting
# and create one if necessary

log_directory = Hanami.root.join("log").to_s
Dir.mkdir(log_directory) unless File.directory?(log_directory)
