# FACT: FileMaker Server Open File Count
#
# PURPOSE: List number of database files currently online
#
# NOTES: Requires Server Stats logging to be enabled in FMS Admin Console
#
# HISTORY
#   2015-02-05 simon_b: created file
#

## filemaker_file_count.rb

require 'etc'
require 'filemaker_utils.rb'

# This version uses the last entry in the Stats.log to determine how
# many files are currently open. However, the log may not be enabled,
# so we check if the log has been updated recently.

def count_from_stats (stats_path)

  # The number of open files is the 8th column in FMS 13 Stats.log file.
  OPEN_COL = 7

  # Stats have been updated within the last 5 minutes?
  stats_updated = (Time.new() - File.ctime (stats_path)) < (5*60)

  setcode do
    if stats_updated
      begin
        # Get last line of log.
        last_line = tail (stats_paths,1)
        cols = last_line.split()

        # Return the column with number of open database files.
        cols[OPEN_COL]
      end
    end
  end
  
end


# Mac version using Stats.log

Facter.add('filemaker_filecount') do

  has_weight 100

  # Mac OS Version
  confine :kernel => :darwin

  # Our log file path.
  STATS_PATH = "/Library/FileMaker Server/Logs/Stats.log"

  count_from_stats (STATS_PATH)
  
end


# Windows version using Stats.log

Facter.add('filemaker_filecount') do

  has_weight 80

  # Windows Version
  confine :kernel => :windows

  # Our log file path.
  STATS_PATH = "C:/Program Files/FileMaker/FileMaker Server/Logs/Stats.log"

  count_from_stats (STATS_PATH)
  
end


# Here we use the lsof command. We can either run this as the fmserver
# user, or as root (otherwise we are out of luck).

Facter.add('filemaker_filecount') do

  has_weight 60

  # Mac OS Version
  confine :kernel => :darwin

  if Etc.getpwuid(Process.euid).name = 'fmserver'
    setcode "lsof -Fn | grep -c '\.fmp12$'"
  elsif 
    setcode "lsof -u fmserver -Fn | grep -c '\.fmp12$'"
  end

end
