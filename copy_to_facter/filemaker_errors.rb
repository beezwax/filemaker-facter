# FACT: FileMaker Server errors
#
# PURPOSE: List the error codes (if any) for any logged error codes in the last 24 hours
#
# NOTES:
#   Assumes logging interval is set to the default 30 second interval and the Event.log has not been rolled recently.
#
#   Testing looks like this:
#     export FACTERLIB="/Users/simon_b/filemaker-facter/filemaker-facts"; facter -d filemaker_errors
#
# HISTORY
#   2015-02-07 simon_b: created file
#   2015-03-27 simon_b: now only returning error messages
#   2015-04-02 simon_b: Windows version
#   2016-01-05 simon_b: now using constants from filemaker_util file
#   2016-01-05 simon_b: now constrain results by time range


require 'etc'
require 'time'
require "facter/filemaker/filemaker_utils"


Facter.add('filemaker_errors') do

     # From right now, how far back in time should we go?
     oldest_error = Time.at(Time.now - MAX_SECONDS)

     # First read in a portion of the log data up to our maximum log lines.
     raw_lines = tail(LOG_EVENTS,EVENTS_TO_CHECK)

     # Further trim out by removing any non-error lines.
     error_lines = raw_lines.scan(/.*\tError\t.*/)
     period_lines = []
     limited_lines = []

     if error_lines != []
        # Loop over each line, adding those that match. 
        # Going backwards could have some advantages. Also, chopping string
        # from start of first line in match instead of looping over all.
        error_lines.each do |line|
           # Line's time stamp within range?
           line_time = Time.parse(line[0..15])
           is_period = line_time > oldest_error
     
           if is_period
              period_lines << line
           end
        end

        max_errors = [MAX_ERRORS,period_lines.count].min
        # Starting from the end, get the last 'max_errors' lines.
        limited_lines = period_lines[-max_errors, max_errors]        
     end

  setcode do
     # This could've been returned as a structured result, but it is a bit more readable as string.
     limited_lines.join("\n")
  end

end
