# FACT: FileMaker Server Network Stats
#
# PURPOSE: summary of recent network activity
#
# NOTES:
#   Assumes logging interval is set to the default 30 second interval, Statistics logging is enabled, and Stats.log has not been rolled recently.
#   Testing looks like this:
#     export FACTERLIB="/Users/simon_b/filemaker-facter/filemaker-facts"; facter -d filemaker_stats_network
#
# HISTORY
#   2015-04-02 simon_b: Created filed

require 'etc'
require_relative "filemaker_utils"


###
### NOT DONE! ####
###


Facter.add('filemaker_stats_network') do

  # Mac OS Version
  confine :kernel => :darwin

  setcode do
     # Change these if too few/too many intervals getting reported.
     events_to_check = 2 * 60 * 24 * 7   # One week

     # Get recent FMS event data.
     raw=tail(LOG_STATS_MAC,events_to_check)
     error_lines = raw.scan(/.*\tError\t.*/)

     if error_lines != []
        # Restrict to the last errors found.
        max_errors = [max_errors,error_lines.count].min
        error_lines_last = error_lines[-max_errors, max_errors]

        # This could've been returned as a structured result, but it is a bit more readable as string.
        error_lines_last.join("\n")
     end
  end
end


Facter.add('filemaker_stats_network') do

  # Windows Version
  confine :kernel => :windows

  setcode do
     # Change this if too few/too many errors getting reported.
     events_to_check = 500
     max_errors = 10

     # Get recent FMS event data.
     raw=tail(LOG_STATS_WIN,events_to_check)
     error_lines = raw.scan(/.*\tError\t.*/)

     if error_lines != []
        # Restrict to the last errors found.
        max_errors = [max_errors,error_lines.count].min
        error_lines_last = error_lines[-max_errors, max_errors]
        
        # This could've been returned as a structured result, but it is a bit more readable as string.
        error_lines_last.join("\n")
     end
  end
end

