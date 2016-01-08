# PURPOSE: Utility functions for facts.
#
# HISTORY
#   2015-02-06 simon_b: created file
#   2015-02-08 simon_b: added constants
#   2015-03-27 simon_b: fixed path, added new ones
#   2015-04-04 simon_b: simplified custom facts by using same names for both Mac & Win
#   2015-04-13 simon_b: added method to check if string is numeric
#   2015-11-25 simon_b: modified fmsadmin path after change to FMS 14.0v4
#   2016-01-05 simon_b: added configuration constants
#

#
# CONFIGURATION CONSTANTS
#

# Change these if too few/too many errors getting reported.
EVENTS_TO_CHECK = 100

# How far to go back in logs (time based). 
MAX_SECONDS = 2*60*60  # 720 seconds, or 2 hours

# Maximum number of errors to return for result.
MAX_ERRORS = 5

#
# is_mac
#

def is_mac
   (/darwin/ =~ RUBY_PLATFORM) != nil
end


#
# MAIN
#

# Paths to commands used.
if is_mac
   AWK_MAC = "/usr/bin/awk"
   # Not the same path used by shell, but this is consistent between FMS versions.
   # The spaces in path are problematic, even escaping with backslashes would fail.
   FMSADMIN = "'/Library/FileMaker Server/Database Server/bin/fmsadmin'"
else
   FMSADMIN = "C:/Program Files/FileMaker/FileMaker Server/fmsadmin"
end

# LOG FILE PATHS
if is_mac
   LOG_CLIENTSTATS = "/Library/FileMaker Server/Logs/ClientStats.log"
   LOG_EVENTS = "/Library/FileMaker Server/Logs/Event.log"
   LOG_STATS = "/Library/FileMaker Server/Logs/Stats.log"
else
   LOG_CLIENTSTATS = "C:/Program Files/FileMaker/FileMaker Server/Logs/ClientStats.log"
   LOG_EVENTS = "C:/Program Files/FileMaker/FileMaker Server/Logs/Event.log"
   LOG_STATS = "C:/Program Files/FileMaker/FileMaker Server/Logs/Stats.log"
end

# STATS LOG COLUMNS
# Values for tab-delimited columns in the Stats.log file.

STATS_TIMESTAMP = 0
STATS_NETIN = 1
STATS_NETOUT = 2
STATS_DISKREAD = 3
STATS_DISKWRITE = 4
STATS_OPENDBS = 8


## filemaker_utils.rb


#
#  i s _ n u m ?
#

class String
   def is_num?
      begin
         !!Float(self)
      rescue ArgumentError, TypeError
         false
      end
   end
end

#
#   l o g _ i s _ c u r r e n t
#

def log_is_current(path)
  stats_updated_at = File.ctime(path)
  return (Time.new() - stats_updated_at) < (5*60)
end

#
#   t a i l
#

# From http://stackoverflow.com/questions/754494/reading-the-last-n-lines-of-a-file-in-ruby/28221975

# TODO: Always returning an extra newline at end.
 
def tail(path, n)
  file = File.open(path, "r")
  buffer_s = 512
  line_count = 0
  file.seek(0, IO::SEEK_END)

  offset = file.pos # we start at the end

  while line_count <= n && offset > 0
    to_read = if (offset - buffer_s) < 0
                offset
              else
                buffer_s
              end

    file.seek(offset-to_read)
    data = file.read(to_read)

    data.reverse.each_char do |c|
      if line_count > n
        offset += 1
        break
      end
      offset -= 1
      if c == "\n"
        line_count += 1
      end
    end
  end

  file.seek(offset)
  return file.read
end

#
#	l a s t _ l i n e _ o f _ l o g
#

# Return the last line from Stats.log if it is current.
# Otherwise return an empty string.

def last_line_of_log(path)

  # If the log file is current, return its last line.
  if log_is_current(path)
    last_line = tail(path,1)
  else
    last_line = ""
  end
  
  return last_line
end
