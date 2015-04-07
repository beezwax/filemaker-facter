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
require "facter/filemaker/filemaker_utils"

#
#       f i l e m a k e r _ f i l e _ c o u n t
#

# This version uses the last entry in the Stats.log to determine how
# many files are currently open. However, the log may not be enabled,
# so we check if the log has been updated recently.

Facter.add('filemaker_file_count') do

  has_weight 100

  setcode do
    last_line = last_line_of_log(LOG_STATS)
    last_line.split("\t")[STATS_OPENDBS]
  end

end


# Here we use the lsof command. We can either run this as the fmserver
# user, or as root (otherwise we are out of luck).

Facter.add('filemaker_file_count') do

  has_weight 60

  # Mac OS Version
  confine :kernel => :darwin

  setcode do
     current_user = Etc.getpwuid(Process.euid).name

     if current_user == "fmserver"
        `lsof -Fn | grep -c '\.fmp12$'`
     elsif current_user == "root"
        `lsof -u fmserver -Fn | grep -c '\.fmp12$'`
     end
  end
end
