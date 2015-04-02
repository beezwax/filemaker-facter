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

require 'etc'
require_relative "filemaker_utils"


Facter.add('filemaker_errors') do

  has_weight 100

  # Mac OS Version
  confine :kernel => :darwin

# Trying to keep compatibility with facter version 1.7 or higher.
# Unfortunately, structured replies not supported until version 2.0.

  # Get recent FMS event data.
  raw=tail(LOG_EVENTS_MAC,500)
  error_lines=raw.scan(/.*\tError\t.*/)

  setcode do
     if error_lines.count
	# If there were a lot of errors, it would be nice to limit the # of errors returned.
	# Use a structured result?
        error_lines.join("\n")
     end
  end
end