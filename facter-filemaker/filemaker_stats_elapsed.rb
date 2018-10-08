# FACT: FileMaker Recent Elapsed Time
#
# PURPOSE: average of recent elapsed time/call times
#
# NOTES:
#   Assumes logging interval is set to the default 30 second interval, Statistics logging is enabled, and Stats.log has not been rolled recently.
#
#   Testing looks like this:
#     FACTERLIB="/Users/simon_b/filemaker-facter/facter-filemaker"; facter -d filemaker_recent_elapsed
#
# HISTORY
#   2017-02-19 simon_b: Created filed
#   2017-03-09 simon_b: now return time in seconds instead of milliseconds
#   2018-10-05 simon_b: made require path relative

# For testing:
#    cp filemaker/filemaker_utils.rb /usr/local/lib/facter-filemaker/filemaker/; cp filemaker_stats_elapsed.rb /usr/local/lib/facter-filemaker/

#require 'etc'
require "facter"
require_relative "filemaker/filemaker_utils"


Facter.add('filemaker_stats_elapsed') do

  setcode do
	 # The title as stored in the Stats.log file.
     intervals = sum_recent_stats("Elapsed Time/call")

     # Return Facter result.
     intervals
  end #do

end
