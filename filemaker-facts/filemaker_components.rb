# FACT: FileMaker Server running components
#
# PURPOSE: List the components that are currently running
#
# NOTES:
#   Assumes logging interval is set to the default 30 second interval and the Event.log has not been rolled recently.
#   Testing looks like this:
#     export FACTERLIB="/Users/simon_b/filemaker-facter/filemaker-facts"; facter -d filemaker_file_count
#
# HISTORY
#   2015-02-07 simon_b: created file

## filemaker_file_count.rb

require 'etc'
require_relative "filemaker_utils"


####
#### UNFINISHED ####
####


Facter.add('filemaker_errors') do

  has_weight 100

  # Mac OS Version
  confine :kernel => :darwin

# Trying to keep compatibility with facter version 1.7 or higher.
# Unfortunately, structured replies not supported until version 2.0.

# ps -wwc -u fmserver

  setcode do
    # Our log file path.
    return tail(LOG_STATS_MAC)
  end
end



