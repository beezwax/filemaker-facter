# FACT: FileMaker Server Version
#
# PURPOSE: Get the version number as reported by the fmsadmin command
#
# NOTES:
#   On Mac OS, we must supply a dummy user and password to avoid getting stuck on credentials prompt
#   that comes after the version information is supplied.
#
# HISTORY
#   2015-02-07 simon_b: created file
#   2018-10-05 simon_b: made require path relative

## filemaker_version.rb

require 'facter'
require_relative 'filemaker/filemaker_utils'

# Mac Version

Facter.add('filemaker_version') do

  confine :kernel => :darwin
  
  fmsadmin_call = FMSADMIN + " -v -u none -p none"
  
  setcode do
    raw = Facter::Util::Resolution.exec(fmsadmin_call)
  
    # Pull out the Version line, only return 2nd word.
    /Version (.*)/.match(raw)[1]
  end

  # Get version info from fmsadmin command, then strip out everything but version number.
  #setcode FMSADMIN + " -v -u NONE -p NONE | " + AWK_MAC + " '/ Version / { print $3 }'"
end


# Windows Version

Facter.add('filemaker_version') do
  
  confine :kernel => :windows

  fmsadmin_call = FMSADMIN + " -v"
  
  setcode do
    raw = Facter::Util::Resolution.exec(fmsadmin_call)
      
    # Pull out the Version line, only return 2nd word.
    /Version (.*)/.match(raw)[1]
  end
end
