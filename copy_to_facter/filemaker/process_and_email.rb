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
# 
# TODO
#
#  windows compatible?
#  --component list must now be in same order as Facter returns them
#  factor out main code block into functions
#  accept To: addresses as command options

 
require 'optparse'
require 'net/smtp'
require 'socket'
require 'yaml'

# GLOBAL CONSTANTS
#
# ASCII graph: value per step of bar graph.
# HTML graphs default to value in $graph_increment
INCR = 200

# email settings

HOSTNAME = Socket.gethostname

# TODO: Use a YAML file for this.
#
E_DOMAIN = "beezwax.net"
E_FROM = HOSTNAME + "@" + E_DOMAIN
E_TOS = ["noone@somedomain.com"]
E_SUBJECT_REPORT = "Facter Report: " + HOSTNAME + "." + E_DOMAIN
E_SUBJECT_ALERT = "Facter Alert: " + HOSTNAME + "." + E_DOMAIN
#E_SMTP = "smtp.somedomain.com"
E_SMTP = "localhost"
E_PORT = 25

E_BAR = '<div style="width: %dpx;">%d</div>'
E_GRAPH_START = '<div class="chart">'
E_GRAPH_END = '</div>'

F_COMPONENTS = 'filemaker_components'
F_ERRORS = 'filemaker_errors'
F_STATS_DISK = 'filemaker_stats_disk'
F_STATS_NETWORK = 'filemaker_stats_network'

# background-color: steelblue;

# GLOBAL VARIABLES
# (may get overridden by OptionParser).
#
$check_failed = false
$email_errors = 0
$email_files = 0
$graph_increment = 100

comp_list = []
email_list = []
error_list = []
raw = ""
send_email = false


# Change to class to allow converting to HTML table
# http://stackoverflow.com/questions/2634024/generate-an-html-table-from-an-array-of-hashes-in-ruby

class Array 
  def to_cells(tag)
    self.map { |c| "<#{tag}>#{c}</#{tag}>" }.join
  end
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

   for row in 0..(stat_rows.count - 1)
      # Clobber the existing array replace with an array of just one string.
      glob += stat_rows[row][0][0..15] + '<br> ' + E_GRAPH_START + (E_BAR % [stat_rows[row][1] / increment, stat_rows[row][1]]) + " " + (E_BAR % [stat_rows[row][2] / increment, stat_rows[row][2]]) + E_GRAPH_END
      #puts stat_rows[row]
   end

   return glob
end


#
#  s e n d _ e m a i l
#

def sendEmail (body)

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

   Net::SMTP.start(E_SMTP, E_PORT) do |smtp|
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
end


OptionParser.new do |opts|

   opts.banner = "Usage: process_for_email.rb [options]"

   opts.on('--components a,b,c,d,e,f,g', Array, 'Send email if listed components are not running') do |components|
      comp_list = components
   end

   opts.on('--errors [count]', Float, 'Send email if errors were logged') do |errors|
      if errors != nil && errors > 0
         $email_errors = errors
      end
   end

   opts.on('--files [count]', Float, 'Send email if there is not at least 1 or count files open') do |files|
      $email_files = files
   end

   opts.on('--graph [increment]', Float, 'Add ASCII graph to stats') do |graph|
      if graph != nil && graph > 0
         $graph_increment = graph
      end
   end

end.parse!


if true
   # Get stdin input, which should be the Facter report in YAML format.
   raw = ARGF.read

   # Load up the facts so that we can check for issues.
   facts = YAML.load(raw)

   running_components = facts[F_COMPONENTS]

   # Need to sort list as intersection function is picky about the order values are specified in.
   if running_components != nil
      running_components.sort!
   end
  
   error_list = facts[F_ERRORS]
   if error_list != nil
      error_list = error_list.split("\n")
   end

   file_count = facts['filemaker_file_count']

   # When using graphing, we replace the existing numeric values with a string
   # containing the numeric value and an ASCII graph.

   if $graph_increment > 0
      # Have switch to use ASCII graphs instead?
      facts[F_STATS_DISK] = graph_array_div(facts [F_STATS_DISK], $graph_increment)
      facts[F_STATS_NETWORK] = graph_array_div(facts [F_STATS_NETWORK], $graph_increment)
   end

   # Always send email when no checks are specified.
   send_email = send_email || (($email_errors == 0) && ($email_files == 0) && (comp_list == []))

   # Below only used for debugging.
   if false
      p "graph_increment: %d" % $graph_increment
      p "send_email: %s" % send_email
      p "error_list: %s" % error_list
      p "email_errors: %d" % $email_errors
      p "email_files: %d" % $email_files
      p "file_count: %d" % file_count.to_f
      p "comp_list: %s" % comp_list.to_s
      p "running_components: %s" % running_components.to_s
   end

   # Send email b/c component(s)s are not online?

   # Are the required components running?
   if !$check_failed && (comp_list != nil)
      comp_list.sort!
      if (running_components & comp_list) != comp_list
         $check_failed = true
         facts[F_COMPONENTS] = '<b>' + facts [F_COMPONENTS] + '</b>'
      end
   end

   # Send b/c enough errors occured?
   if error_list.class == String
      error_count = 1
   elsif error_list.class == Array
      error_count = error_list.count
   else
      error_count = 0
   end

   # Too many errors found in Event log?
   if (($email_errors > 0) && (error_count >= $email_errors))
      $check_failed = true
      facts[F_ERRORS] = '<b>' + facts [F_ERRORS] + '</b>'
   end

   # Send b/c too few files are online?
   $check_failed = $check_failed || ($email_files != 0) && (file_count.to_f < $email_files)

   if send_email | $check_failed
       #sendEmail (YAML.dump(facts))
       sendEmail (facts)
   end
end

