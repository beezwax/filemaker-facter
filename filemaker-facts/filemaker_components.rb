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
#   2015-04-02 simon_b: working Mac OS version

## filemaker_components.rb

require 'etc'
require_relative "filemaker_utils"


Facter.add('filemaker_components') do

  # Mac OS Version
  confine :kernel => :darwin

  running = []

  # ps -wwc -u fmserver -o comm | grep -v COMM | sort -u

  # Need the full command so that we can check for the fmadminserver applet.
  raw = `ps -u fmserver -o command`

  if raw.include? "FMS.COMPONENT=fmadminserver"
    running.push ("ADMINSERVER")
  end

  if raw.include? "bin/fmsib"
    running.push ("FMSIB")
  end

  if  raw.include? "bin/fmsased"
    running.push ("FMSE")
  end

  if  raw.include? "bin/fmserverd"
    running.push ("SERVER")
  end

  if  raw.include? "bin/fmscwpc"
    running.push ("WPE")
  end

  if  raw.include? "./fmxdbc_listener"
    running.push ("XDBC")
  end

  if  raw.include? "bin/fmserver_helperd"
    running.push ("fmserver_helperd")
  end

  if  raw.include? "sbin/httpd"
    running.push ("httpd")
  end

  if  raw.include? "bin/fmslogtrimmer"
    running.push ("fmslogtrimmer")
  end

  setcode do
    running
  end
end



