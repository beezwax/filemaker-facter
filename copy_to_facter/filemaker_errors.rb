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
#   2015-03-27 simon_b: now only returning error messages
#   2015-04-02 simon_b: Windows version

require 'etc'
require "facter/filemaker/filemaker_utils"


Facter.add('filemaker_errors') do

  setcode do
     # Change these if too few/too many errors getting reported.
     events_to_check = 300
     max_errors = 10

     # Get recent FMS event data.
     raw=tail(LOG_EVENTS,events_to_check)
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

