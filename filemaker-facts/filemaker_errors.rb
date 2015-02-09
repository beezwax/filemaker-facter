# FACT: FileMaker Server errors
#
# PURPOSE: List the error codes (if any) for any logged error codes in the last 24 hours
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

# Testing with Ruby 2.0, why doesn't this work?
# require_relative("filemaker_utils")
require "#{File.dirname(__FILE__)}/filemaker_utils"

# The number of open files is the 8th column in FMS 13 Stats.log file.
OPEN_COL = 7



# Mac version using Stats.log

# UNFINISHED

Facter.add('filemaker_errors') do

  has_weight 100

  # Mac OS Version
  confine :kernel => :darwin

  setcode do
    # Our log file path.
    return tail(STATS_LOG_MAC)
  end  
end



