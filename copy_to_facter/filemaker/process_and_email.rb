#!/usr/bin/ruby

# PURPOSE
# 
# This script can be used to email out the Facter report.
# When nothing is set to be checked, an email will always be
# sent. Or, check for various conditions, and an, email is only
# sent when any one of the conditions is met.

# Additionally, the message can create graphs for a handful
# of values.
#
# Some examples of usage (assuming in same directory as this file):
#    facter -y | ./process_and_email --graph
#    facter -y | ./process_and_email --graph --components ADMINSERVER,SERVER,WPE,httpd
#    facter -y | ./process_and_email --errors 4 --files 10
#    facter -y filemaker_components filemaker_errors filemaker_file_count filemaker_stats_disk filemaker_stats_network | ./process_and_email.rb --graph
#
# HISTORY
#
# 2015-04-07 simon_b: created file
# 2015-04-07 simon_b: scaled down div graph size
# 2015-04-16 simon_b: graphs now take optional step incremement parameter
# 2016-01-07 simon_b: changed the doctype to use the commonly used xHTML strict form
# 2016-01-07 simon_b: now flagging errors & component issues out of range
# 2016-02-01 simon_b: fixes for two incorrect code blocks
# 2016-03-08 simon_b: now specify helo for SMTP connection
# 2017-02-22 simon_b: added --debug option
# 2017-02-24 simon_b: empty file count no longer causes exception
# 2017-02-24 simon_b: uptime check added
# 2017-02-24 simon_b: factored check for error messages

# 
# TODO
#
#  windows compatible?
#  --component list must now be in same order as Facter returns them
#  factor out main code block into functions
#  accept To: addresses as command options


require 'net/smtp'
require 'optparse'
require 'socket'
require 'yaml'

# GLOBAL CONSTANTS
#

# email settings

# =================================================
#
#   MOST OF THESE WILL NEED TO BE EDITED

E_DOMAIN = "some.domain"
E_TOS = ["noone@somedomain.com"]
E_SMTP = "localhost"
E_PORT = 25

#
# =================================================

# ASCII graph: value per step of bar graph.
# HTML graphs default to value in $graph_increment
INCR = 200

if RUBY_PLATFORM.include? "darwin"
   # Ruby on macOS is inconsistent about whether we get just the host name.
   # "universal.x86_64-darwin13"
   HOSTNAME = Socket.gethostname.split(".")[0]
else
   HOSTNAME = Socket.gethostname
end

E_FQD = HOSTNAME + "." + E_DOMAIN
E_FROM = HOSTNAME + "@" + E_DOMAIN
E_SUBJECT_REPORT = "Facter Report: " + E_FQD
E_SUBJECT_ALERT = "Facter Alert: " + E_FQD

E_BAR = '<div style="width: %dpx;">%d</div>'
E_GRAPH_START = '<div class="chart">'
E_GRAPH_END = '</div>'

F_COMPONENTS = 'filemaker_components'
F_ERRORS = 'filemaker_errors'
F_FILE_COUNT = 'filemaker_file_count'
F_STATS_DISK = 'filemaker_stats_disk'
F_STATS_ELAPSED = 'filemaker_stats_elapsed'
F_STATS_NETWORK = 'filemaker_stats_network'
F_UPTIME = 'sp_uptime'

# Codes used to indicate alert types.
C_COMPONENT = 'C'
C_ELAPSED = 'e'
C_ERROR = 'E'
C_FILE = 'F'
C_UPTIME = 'U'

LAST_ALERT_PATH = '/tmp/process_and_email.last'


# GLOBAL VARIABLES
# (some of these may get overridden by OptionParser).
#
$alert_codes = ''
$always_email = false
$check_failed = false
$debug = true
$elapsed_maximum = 0
$errors_maximum = 0
$files_minimum = 0
$graph_increment = 100
$uptime_minimum = 0 # minutes

# These may be filled in if their respective command line options are used.
comp_list = []
email_list = []
error_list = []

raw = ""
send_flag = false


# Change to class to allow converting to HTML table
# http://stackoverflow.com/questions/2634024/generate-an-html-table-from-an-array-of-hashes-in-ruby

class Array 
  def to_cells(tag)
    self.map { |c| "<#{tag}>#{c}</#{tag}>" }.join
  end
end


#
#  save_last_alerts
#

def write_last_alerts(code)

   begin
      f = File.open(LAST_ALERT_PATH,'w');
      f.write(code);
   rescue IOError => e
      puts 'Could not write last alert info'
   end
   f.close
end


#
#  read_last_alert
#

def read_last_alert()

   begin
      f = File.open(LAST_ALERT_PATH,'r');
      code = f.read;
      f.close
   rescue Errno::ENOENT => e
      # Hopefully here just b/c the file did not exist yet.
      write_last_alerts("")
      code = ""
   end

   return code
end


#
#  g r a p h _ a r r a y _ a s c i i
#

def graph_array_ascii(stat_rows)
   # filemaker_stats_disk => [["2015-04-01 11:37:03.030 -0700", 1649.0, 679.0], ["2015-04-02 11:37:03.346 -0700", 149.0, 318.0], ["2015-04-03 11:37:03.176 -0700", 24.0, 232.0], ["2015-04-04 11:37:03.

   for row in 0..(stat_rows.count - 1) 
      # Just show the date, hour, and minute
      stat_rows[row][0] = stat_rows[row][0][0..15]

      # value + ASCII graph
      stat_rows[row][1] = ("%8d %s" % [stat_rows[row][1], "#" * (stat_row[row][1] / INCR)]).gsub(/ /,"&nbsp;")
      stat_rows[row][2] = ("%8d %s" % [stat_rows[row][2], "#" * (stat_rows[row][2] / INCR)]).gsub(/ /,"&nbsp;")
   end
   return stat_row
end


#
#  g r a p h _ a r r a y _ d i v
#

# increment: amount to divide value by (eg, changes how much is required for each step in graph)
# stat_rows: an array of one or more rows of values to be graphed

def graph_array_div (stat_rows,increment=10)

   glob = ""

   if stat_rows.kind_of? Array
      for row in 0..(stat_rows.count - 1)
         # Clobber the existing array and replace with a string of HTML.
         glob += stat_rows[row][0][0..15] + '<br> ' + E_GRAPH_START + (E_BAR % [stat_rows[row][1] / increment, stat_rows[row][1]]) + " " + E_GRAPH_END
      end
   end

   return glob
end


#
#  g r a p h _ a r r a y _ p a i r _ d i v
#

# Has two data points per time period.
# increment: amount to divide value by (eg, changes how much is required for each step in graph)
# stat_rows: an array of one or more rows of values to be graphed

def graph_array_pair_div (stat_rows,increment=10)

   glob = ""

   for row in 0..(stat_rows.count - 1)
      # Clobber the existing array and replace with a string of HTML.
      glob += stat_rows[row][0][0..15] + '<br> ' + E_GRAPH_START + (E_BAR % [stat_rows[row][1] / increment, stat_rows[row][1]]) + " " + (E_BAR % [stat_rows[row][2] / increment, stat_rows[row][2]]) + E_GRAPH_END
   end

   return glob
end


#
#  p r o c e s s _ c o m p o n e n t s
#

def process_components(facts, comp_list)

   running_components = facts[F_COMPONENTS]

   # Need to sort list as intersection function is picky about the order values are specified in.
   if running_components != nil
      running_components.sort!
   end

   if $debug
      p "running_components: %s" % running_components.to_s
   end

   # Send email b/c component(s)s are not online?

   # Are the required components running?
   if comp_list != nil
      comp_list.sort!
      if (running_components & comp_list) != comp_list
         $alert_codes += C_COMPONENT
         # Embolden b/c we found an issue.
         facts[F_COMPONENTS] = '<b>' + running_components.join(",") + '</b>'
      end
   end

end

#
#  p r o c e s s _ e r r o r s
#

def process_errors(facts)

   error_list = facts[F_ERRORS]

   if error_list != nil
      if error_list.class == String
         error_list = error_list.split("\n")
         error_count = 1
      elsif error_list.class == Array
         error_count = error_list.count
      else
         error_count = 0
      end

      # Too many errors found in Event log?
      if (($errors_maximum > 0) && (error_count >= $errors_maximum))
         $alert_codes += C_ERROR
         facts[F_ERRORS] = '<b>' + facts [F_ERRORS] + '</b>'
      end
   end

   if $debug
      p "error_count: %d" % error_count
      p "errors_maximum: %d" % $errors_maximum
      if error_list != nil
         p "error_list: %s" % error_list.join(",")
      else
         p "error_list:"
      end
   end

   return error_list
end


#
#  s e n d _ e m a i l
#

def send_email(body)

   # Since we are using HTML formatting, convert line endings to BRs.
   if $graph_increment == 0
      body_yaml =YAML.dump(body)
      body_html = body_yaml.gsub(/\n/, "<br>\n")
   else
      headers = ["Fact","Values"]
      cells = body.map do |row|
         if row.class == Array
            "<tr>#{row.to_cells('td')}</tr>"
         elsif row.class == Hash
            "<tr>#{row.values.to_cells('td')}</tr>"
         else
            "<tr>#{row}</tr>"
         end
      end.join("\n  ")

# removed at this time: #{headers}

body_html = "<table border=1>
  #{cells}
</table>"

   end

   Net::SMTP.start(E_SMTP, E_PORT, E_FQD) do |smtp|
      smtp.open_message_stream(E_FROM,E_TOS) do |f|
         f.puts 'From: ' + E_FROM
         f.puts 'To: ' + E_TOS.join(',')

         if $check_failed
            subject_title = E_SUBJECT_ALERT
            f.puts 'Subject: ' + subject_title
            # Set high priority.
            f.puts 'X-Priority: 1'
         else
            subject_title = E_SUBJECT_REPORT
            f.puts 'Subject: ' + subject_title
            # Set low priority as used by Mail.app.
            f.puts 'X-Priority: 5'
         end

         f.puts 'MIME-Version: 1.0'
         f.puts 'Content-type: text/html'
         f.puts '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">'
         f.puts '<html xmlns="http://www.w3.org/1999/xhtml">'
         f.puts '<head>'
         f.puts    '<title>' + subject_title + '</title>'
         f.puts '</head>'
         f.puts '<font size=2 face="Menlo","courier-new","Courier">'

         if $graph_increment > 0
            f.puts '<style>'
            f.puts    'table { border: 0px;}'
            f.puts    'th,td { border: 1px solid LightSteelBlue;}'
            f.puts    '.chart div { font: 10px sans-serif; background-color: steelblue; text-align: right; padding: 3px; margin: 1px; color: white; }'
            f.puts '</style>'
         end

         f.puts
         f.puts body_html
      end
   end
end  # send_email


#
#	MAIN
#

OptionParser.new do |opts|

   opts.banner = "Usage: process_for_email.rb [options]"

   opts.on('-a','--always-email','Send email even if no errors') do |always_email|
      $always_email = true
   end
 
   opts.on('--components a,b,c,d,e,f,g', Array, 'Send email if listed components are not running') do |components|
      comp_list = components
   end

   opts.on('-d','--debug', 'Enable debug output') do |debug|
      $debug = debug
   end

   opts.on('--elapsed [microseconds]', Float, 'Send email if errors were logged') do |microseconds|
      if microseconds != nil && microseconds > 0
         $elapsed_maximum = microseconds
      else
         $elapsed_maximum = 10000
      end
   end

   opts.on('--errors [count]', Float, 'Send email if errors were logged') do |errors|
      if errors != nil && errors > 0
         $errors_maximum = errors
      else
         $errors_maximum = 1
      end
   end

   opts.on('--files [count]', Float, 'Send email if there is not at least 1 or [count] files open') do |files|
      if files != nil && files > 0
         $files_minimum = files
      else
         $files_minimum = 1
      end
   end

   opts.on('--graph [increment]', Float, 'Add ASCII graph to stats') do |graph|
      if graph != nil && graph > 0
         $graph_increment = graph
      end
   end

   opts.on('--uptime [minutes]', Float, 'Send email if uptime is below 60 minutes or optional limit') do |minutes|
      if minutes != nil && minutes > 0
         $uptime_minimum = minutes
      else
         $uptime_minimum = 60
      end
   end

end.parse!


if true
   # Get stdin input, which should be the Facter report in YAML format.
   raw = ARGF.read

   # Load up the facts so that we can check for issues.
   facts = YAML.load(raw)


   # COMPONENTS

   # Check for component issues.
   process_components(facts, comp_list)


   # ERRORS

   # Check for recent error messages.
   error_list = process_errors(facts)


   # ELAPSED TIME

   elapsed_ms = facts[F_STATS_ELAPSED]
   if elapsed_ms != nil
      elapsed_ms = elapsed_ms.last[1].to_f
   else
      elapsed_ms = 0
   end

   # Send b/c over maximum?
   if elapsed_ms > $elapsed_maximum
      $alert_codes += C_ELAPSED
      # Can't use the method below b/c we use graph_array_div to draw the array.
      # Will need to either highlight the name instead, or modify graph_array_div to accept a embolden flag.
      #    facts[F_STATS_ELAPSED] = '<b>%d</b>' % elapsed_ms
   end

   if $debug
      p "elapsed_ms: %d" % elapsed_ms
   end


   # FILE COUNT

   file_count = facts['filemaker_file_count']
   if file_count != nil
      file_count = file_count.to_f
   else
      file_count = 0
   end

   if $debug
      p "file_count: %d" % file_count
   end

   # Send b/c too few files are online?
   if ($files_minimum != 0) && (file_count < $files_minimum)
      $alert_codes += C_FILE
      facts[F_FILE_COUNT] = '<b>%d</b>' % file_count
   end


   # DISK, ELAPSED, NETWORK STATS

   # When using graphing, we replace the existing numeric values with a string
   # containing the numeric value and an ASCII graph.

   if $graph_increment > 0
      # Have switch to use ASCII graphs instead?
      facts[F_STATS_DISK] = graph_array_pair_div(facts [F_STATS_DISK], $graph_increment)
      facts[F_STATS_ELAPSED] = graph_array_div(facts [F_STATS_ELAPSED], $graph_increment)
      facts[F_STATS_NETWORK] = graph_array_pair_div(facts [F_STATS_NETWORK], $graph_increment)
   end

   if $debug
      p "F_STATS_DISK: %s" % facts[F_STATS_DISK]
      p "F_STATS_ELAPSED: %s" % facts[F_STATS_ELAPSED]
      p "F_STATS_NETWORK: %s" % facts[F_STATS_NETWORK]
   end


   # UPTIME

   # format is in the form of "up 0:0:10:25" (0 days, 0 hours, 10 minutes, 25 seconds)   

   uptime_array = facts[F_UPTIME].split(":")
   #p "uptime_array: %s" % uptime_array

   # Convert into number of minutes up.
   uptime_minutes = uptime_array[0].to_f * 1440 + uptime_array[1].to_f * 60 + uptime_array[2].to_f

   # Unexpected reboot?
   if uptime_minutes < $uptime_minimum
      $alert_codes += C_UPTIME
      facts[F_UPTIME] = '<b>%s</b>' % facts[F_UPTIME]
   end

   # Get error codes from previous run, and then overwrite with the ones we have now.
   last_alerts = read_last_alert()
   write_last_alerts ($alert_codes)
   
   # Get the union of the current error codes and the previous ones.
   code_overlap = last_alerts.chars.sort & $alert_codes.chars.sort

   # Must be something new b/c the union is smaller.
   new_code_flag = code_overlap.count < $alert_codes.length

   # Extra output when debugging.
   if $debug
      p "alert_codes: %s" % $alert_codes
      p "comp_list: %s" % comp_list.to_s
      p "files_minimum: %d" % $files_minimum
      p "graph_increment: %d" % $graph_increment
      p "new_code_flag: %s" % new_code_flag
      p "send_flag: %s" % send_flag
   end

   # SENDING EMAIL?

   if $always_email || new_code_flag
      send_email (facts)
   end
end
