# FACT: FileMaker Server Version
#
# PURPOSE: Get the version number as reported by the fmsadmin command
#
# NOTES:
#   We must supply a dummy user and password to avoid getting stuck on prompt.
#
# HISTORY
#   2015-02-07 simon_b: created file

## filemaker_version.rb

# require_relative("filemaker_utils")
require "#{File.dirname(__FILE__)}/filemaker_utils"

# Mac version

Facter.add('filemaker_version') do

  has_weight 100

  confine :kernel => :darwin

  # Get version info from fmsadmin command, then strip out everything but version number.
  setcode FMSADMIN_MAC + " -v -u NONE -p NONE | awk '/ Version / { print $3 }'"
end


# Windows version using Stats.log

Facter.add('filemaker_file_count') do

  has_weight 80

  # Windows Version
  confine :kernel => :windows

# SOMEHOW USE A SYNTAX LIKE THIS?
# set "value=%version*\Version\=%"

  setcode FMSADMIN_WIN + "-v -u NONE -p NONE"
    
end
