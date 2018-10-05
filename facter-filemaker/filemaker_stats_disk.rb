# FACT: FileMaker Server Disk Stats
#
# PURPOSE: summary of recent disk activity
#
# NOTES:
#   Assumes logging interval is set to the default 30 second interval, Statistics logging is enabled, and Stats.log has not been rolled recently.
#
#   Testing looks like this:
#      FACTERLIB="/Users/simon_b/filemaker-facter/facter-filemaker"; facter -d filemaker_stats_disk
#
# HISTORY
#   2015-04-04 simon_b: Created filed
#   2015-04-13 simon_b: fix to avoid first line if header

require 'etc'
require "facter"
require_relative 'filemaker/filemaker_utils'


Facter.add('filemaker_stats_disk') do

  setcode do
     # Change this to adjust the period reported.
     break_interval = 2 * 60 * 24
     rows_to_check = break_interval * 7   # One week, minus one b/c index is zero based.

     # Get recent FMS stats data for up to our total number of rows.
     raw=tail(LOG_STATS,rows_to_check)

     intervals = []

     # Index into lines, relative to start of interval
     break_index = 1

     sum_timestamp = ""
     sum_read = 0.0
     sum_write = 0.0

     raw.each_line do |line|
        columns = line.split("\t")

        if break_index == 1
           sum_timestamp = columns [STATS_TIMESTAMP]
           sum_read = 0.0
           sum_write = 0.0

           # Skip if this is the header.
           if !columns [STATS_DISKREAD].is_num?
              break_index += 1
              next
           end
        end

        sum_read += Float(columns [STATS_DISKREAD])
        sum_write += Float(columns [STATS_DISKWRITE])

        # End of an interval we are summing up?
        if break_index >= break_interval
           # print columns [STATS_TIMESTAMP], " ", columns [STATS_DISKREAD], " ", columns [STATS_DISKWRITE], " ", sum_read, " ", sum_write, "\n"

           # Add in the sums for this breakout point.
           intervals.push([sum_timestamp, sum_read, sum_write])
           break_index = 1
        else
           break_index += 1
        end
     end

     # Return Facter result.
     intervals
  end

end
