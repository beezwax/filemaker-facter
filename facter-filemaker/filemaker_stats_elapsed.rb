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
#    cp filemaker/filemaker_utils.rb /Library/Ruby/Site/facter/filemaker/; cp filemaker_stats_elapsed.rb /Library/Ruby/Site/facter/ 

require 'etc'
require "facter"
require_relative "filemaker/filemaker_utils"


Facter.add('filemaker_stats_elapsed') do

  setcode do
     # Change this to adjust the period reported.
     break_interval = 2 * 60 * 1  # Get an hours worth of log entries.

     rows_to_check = break_interval * 7   # One week, minus one b/c index is zero based.

     # The exact column used varies depending on what's enabled.
     ## head -1 /Library/FileMakerServer/Logs/Stats.log | tr "\t" "\n" | grep "Elapsed Time/call"   
     stats_columns = column_names_for_log (LOG_STATS)

     elapsed_col = stats_columns.index ("Elapsed Time/call")

     if elapsed_col == nil
        intervals = ["NO DATA"]

     else

        # Get recent FMS stats data for up to our total number of rows.
        raw=tail(LOG_STATS,rows_to_check)

        intervals = []

        # Index into lines, relative to start of interval
        break_index = 1

        sum_timestamp = ""
        sum_elapsed = 0.0

        raw.each_line do |line|
           columns = line.split("\t")

           if break_index == 1
              sum_timestamp = columns [STATS_TIMESTAMP]
              sum_elapsed = 0.0

              # Skip if this is the header.
              if !columns [elapsed_col].is_num?
                 break_index += 1
                 next
              end
           end

           # Extract milliseconds elapsed and convert to seconds.
           sum_elapsed += Float(columns [elapsed_col]) / 1000

           # End of an interval we are summing up?
           if break_index >= break_interval
              # print columns [STATS_TIMESTAMP], " ", columns [elapsed_col], " ", sum_elapsed, "\n"

              # Add in the sums for this breakout point.
              intervals.push([sum_timestamp, sum_elapsed])
              break_index = 1
           else
              break_index += 1
           end

         end #do

     end #if

     # Return Facter result.
     intervals
  end #do

end
