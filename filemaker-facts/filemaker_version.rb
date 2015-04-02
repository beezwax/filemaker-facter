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

## filemaker_version.rb

require 'facter'
require_relative 'filemaker_utils'

# Mac Version

Facter.add('filemaker_version') do

  has_weight 100
  
  confine :kernel => :darwin
  
  fmsadmin_call = FMSADMIN_MAC + " -v -u none -p none"
  
  setcode do
    raw = Facter::Util::Resolution.exec(fmsadmin_call)
  
    # Pull out the Version line, only return 2nd word.
    /Version (.*)/.match(raw)[1]
  end

  # Get version info from fmsadmin command, then strip out everything but version number.
  #setcode FMSADMIN_MAC + " -v -u NONE -p NONE | " + AWK_MAC + " '/ Version / { print $3 }'"
end

# Windows Version

Facter.add('filemaker_version') do

  has_weight 80
  
  confine :kernel => :windows

  fmsadmin_call = FMSADMIN_WIN + " -v"
  
  setcode do
    raw = Facter::Util::Resolution.exec(fmsadmin_call)
      
    # Pull out the Version line, only return 2nd word.
    /Version (.*)/.match(raw)[1]
  end
end