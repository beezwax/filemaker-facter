# PURPOSE: Utility functions for facts.
#
# HISTORY
#   2015-02-06 simon_b: created file
#   2015-02-08 simon_b: added constants

# Paths to the fmsadmin command.
FMSADMIN_MAC = "/usr/bin/fmsadmin"
FMSADMIN_WIN = ""C:/Program Files/FileMaker/FileMaker Server/fmsadmin"

# LOG FILE PATHS
LOG_EVENTS_MAC = "/Library/FileMaker Server/Logs/Eventss.log"
LOG_STATS_MAC = "/Library/FileMaker Server/Logs/Stats.log"

# STATS LOG COLUMNS
# Values for tab-delimited columns in the Stats.log file.
STATS_NETIN = 1
STATS_NETOUT = 2
STATS_DISKREAD = 3
STATS_DISKWRITE = 4
STATS_OPENDBS = 7


## filemaker_utils.rb

def log_is_current (path)
  stats_updated_at = File.ctime(stats_path)
  return (Time.new() - stats_updated_at) < (5*60)
end

# From http://stackoverflow.com/questions/754494/reading-the-last-n-lines-of-a-file-in-ruby/28221975

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
