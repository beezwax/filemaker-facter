# FACT: FileMaker Recent I/O Time
#
# PURPOSE: average of recent I/O time/call times
#
# NOTES:
#   Assumes logging interval is set to the default 30 second interval, Statistics logging is enabled, and Stats.log has not been rolled recently.
#
#   Testing looks like this:
#     FACTERLIB="/Users/simon_b/filemaker-facter/facter-filemaker"; facter -d filemaker_recent_io_time
#
# HISTORY
#   2018-10-07 simon_b: Created filed

# For testing:
#    cp filemaker/filemaker_utils.rb /usr/local/lib/facter-filemaker/filemaker/; cp filemaker_stats_io_time.rb /usr/local/lib/facter-filemaker/

#require 'etc'
require "facter"
require_relative "filemaker/filemaker_utils"


Facter.add('filemaker_stats_io_time') do

  setcode do
	  # The title as stored in the Stats.log file.
     intervals = sum_recent_stats("I/O Time/call")

	 # Return Facter result.
     intervals
  end #do

end
