# FACT: FileMaker Server running components
#
# PURPOSE: List the components that are currently running
#
# NOTES:
#
#   No Windows version at this time.
#
#   Testing looks like this:
#     FACTERLIB="/Users/simon_b/filemaker-facter/facter-filemaker"; facter -d filemaker_components
#
# HISTORY
#   2015-02-07 simon_b: created file
#   2015-04-02 simon_b: working Mac OS version
#   2015-04-05 simon_b: code now wrapped in setcode to avoid error on Windows
#   2015-04-16 simon_b: minor change to the order components are returned in
#   2018-10-05 simon_b: made require path relative


require_relative 'filemaker/filemaker_utils'

Facter.add('filemaker_components') do

  # Mac OS Version
  confine :kernel => :darwin

  running = []

  setcode do

     # ps -wwc -u fmserver -o comm | grep -v COMM | sort -u

     # Need the full command so that we can check for the fmadminserver applet.
     raw = `ps -u fmserver -o command`

     if raw.include? "FMS.COMPONENT=fmadminserver"
       running.push("ADMINSERVER")
     end

     if raw.include? "bin/fmsased"
        running.push("FMSE")
     end

     if raw.include? "bin/fmsib"
        running.push("FMSIB")
     end

     if raw.include? "bin/fmserverd"
        running.push("SERVER")
     end

     if raw.include? "bin/fmscwpc"
        running.push("WPE")
     end

     if raw.include? "./fmxdbc_listener"
        running.push("XDBC")
     end

     if raw.include? "bin/fmserver_helperd"
        running.push("fmserver_helperd")
     end

     if raw.include? "sbin/httpd"
        running.push("httpd")
     end

     if raw.include? "bin/fmslogtrimmer"
        running.push("fmslogtrimmer")
     end

     running
  end
end
