# FACT: FileMaker Server Open File Count
#
# PURPOSE: List number of database files currently online
#
# NOTES:
#   Optimal methods require Server Stats logging to be enabled in FMS Admin Console.
#   Testing:
#     export FACTERLIB="/Users/simon_b/filemaker-facter/filemaker-facts"; facter -d filemaker_file_count
#
# HISTORY
#   2015-02-05 simon_b: created file
#   2015-02-07 simon_b: factored out testing of recent log activity

## filemaker_file_count.rb

require 'etc'

# Testing with Ruby 2.0, why doesn't this work?
require "filemaker_utils"
#require "#{File.dirname(__FILE__)}/filemaker_utils"


#
#       f i l e m a k e r _ f i l e _ c o u n t
#

# Mac version
# This version uses the last entry in the Stats.log to determine how
# many files are currently open. However, the log may not be enabled,
# so we check if the log has been updated recently.

Facter.add('filemaker_file_count') do

  has_weight 100

  confine :kernel => :darwin

  setcode do
    last_line = last_line_of_log(LOG_STATS_MAC)
    puts("last_line: " + last_line)
    puts("DBS: " + last_line.split()[STATS_OPENDBS])
    return last_line.split()[STATS_OPENDBS]
  end

end

#
#       f i l e m a k e r _ f i l e _ c o u n t
#

# Windows version using Stats.log to return the current number of open database files.

Facter.add('filemaker_file_count') do

  has_weight 80

  confine :kernel => :windows

  setcode do
    last_line = last_line_of_log(LOG_STATS_WIN)
    return last_line.split()[STATS_OPENDBS]
  end

end


# Here we use the lsof command. We can either run this as the fmserver
# user, or as root (otherwise we are out of luck).

Facter.add('filemaker_file_count') do

  has_weight 60

  # Mac OS Version
  confine :kernel => :darwin

  current_user = Etc.getpwuid(Process.euid).name

  if current_user = "fmserver"
    setcode "lsof -Fn | grep -c '\.fmp12$'"
  elsif current_user = "root"
    setcode "lsof -u fmserver -Fn | grep -c '\.fmp12$'"
  end

end
