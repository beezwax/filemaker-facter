# PURPOSE: Utility functions for facts.
#
# HISTORY
#   2015-02-06 simon_b: created file
#   2015-02-08 simon_b: added constants
#   2015-03-27 simon_b: fixed path, added new ones
#   2015-04-04 simon_b: simplified custom facts by using same names for both Mac & Win

def is_mac
   (/darwin/ =~ RUBY_PLATFORM) != nil
end

# Paths to commands used.
if is_mac
   AWK_MAC = "/usr/bin/awk"
   FMSADMIN = "/usr/bin/fmsadmin"
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

def log_is_current (path)
  stats_updated_at = File.ctime(path)
  return (Time.new() - stats_updated_at) < (5*60)
end

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
