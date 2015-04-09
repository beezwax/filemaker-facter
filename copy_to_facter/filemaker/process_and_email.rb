#!/usr/bin/ruby

# PURPOSE
# 
# This script can be used to email out the Facter report. Optionally, an email can
# only be sent if certain conditions are met. 
#
# Typical usage would look like this:
#    facter -y | process_and_email | mail -E simon@beezwax.nodomain,joe@beezwax.nodomain
#
# HISTORY
#
# 2015-04-07 simon_b: created file


require 'optparse'
require 'net/smtp'
require 'socket'
require 'yaml'

# GLOBAL CONSTANTS
#
INCR = 200

# email settings

HOSTNAME = Socket.gethostname

# TODO: Use a YAML file for this.
#
E_DOMAIN = "somedomain.com"
E_FROM = HOSTNAME + "@" + E_DOMAIN
E_TOS = ["simon_b@beezwax.none"]
E_SUBJECT = "Facter Report: " + HOSTNAME + "." + E_DOMAIN
#E_SMTP = "mail.somedomain.com"
E_SMTP = "localhost"
E_PORT = 25

E_BAR = '<div style="width: %dpx;">%d</div>'
E_GRAPH_START = '<div class="chart">'
E_GRAPH_END = '</div>'

# background-color: steelblue;

# GLOBAL VARIABLES
# (some will get stomped on by OptionParser).
#
check_failed = false
comp_list = []
email_errors = 0
email_files = 0
email_list = []
error_list = []
raw = ""
send_email = false
use_graphs = false


def cells_to_tag(c,tag)
    return map { |c| "<#{tag}>#{c}</#{tag}>" }.join
end

# Change to class to allow converting to HTML table
# http://stackoverflow.com/questions/2634024/generate-an-html-table-from-an-array-of-hashes-in-ruby

class Array 
  def to_cells(tag)
    self.map { |c| "<#{tag}>#{c}</#{tag}>" }.join
  end
end


#
#  g r a p h _ 2 _ s t a t s _ a s c i i
#

def graph_2_stats_ascii(stat_rows)
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
#  g r a p h _ 2 _ s t a t s _ d i v
#

def graph_2_stats_div (stat_rows)

   glob = ""

   for row in 0..(stat_rows.count - 1)
      # Clobber the existing array replace with an array of just one string.
      glob += stat_rows[row][0][0..15] + '<br> ' + E_GRAPH_START + (E_BAR % [stat_rows[row][1],stat_rows[row][1]]) + " " + (E_BAR % [stat_rows[row][2],stat_rows[row][2]]) + E_GRAPH_END
      #puts stat_rows[row]
   end

   return glob
end


#
#  s e n d _ e m a i l
#

def send_email (body)

   # Since we are using HTML formatting, convert line endings to BRs.
   #body_brd = body.gsub(/\n/, "<br>\n")

   headers = ["Fact","Values"]
   cells = body.map do |row|
      p row
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

   Net::SMTP.start(E_SMTP, E_PORT) do |smtp|
      smtp.open_message_stream(E_FROM,E_TOS) do |f|
         f.puts 'From: ' + E_FROM
         f.puts 'To: ' + E_TOS.join(',')
         f.puts 'Subject: ' + E_SUBJECT
         f.puts 'MIME-Version: 1.0'
         f.puts 'Content-type: text/html'
         f.puts
         f.puts '<!DOCTYPE html>'
         f.puts '<font face="Menlo","courier-new","Courier"">'
         f.puts '<style>'
         f.puts 'table { border: 0px;}'
         f.puts 'th,td { border: 1px solid LightSteelBlue;}'
         f.puts '.chart div { font: 10px sans-serif; background-color: steelblue; text-align: right; padding: 3px; margin: 1px; color: white; }'
         f.puts '</style>'
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
      email_errors = errors
   end

   opts.on('--files [count]', Float, 'Send email if there is not at least 1 or count files open') do |files|
      email_files = files
   end

   opts.on('--[no-]graph', 'Add ASCII graph to stats') do |graph|
      use_graphs = graph
   end

end.parse!


if true
   # Get stdin input, which should be the Facter report in YAML format.
   raw = ARGF.read

   # Load up the facts so that we can check for issues.
   facts = YAML.load(raw)
   running_components = facts['filemaker_components']
   error_list = facts['filemaker_errors'].split("\n")
   file_count = facts['filemaker_file_count']
   stats_disk = facts['filemaker_stats_disk']
   stats_network = facts['filemaker_stats_network']

   # When using graphing, we replace the existing numeric values with a string
   # containing the numeric value and an ASCII graph.

   if use_graphs
      facts['filemaker_stats_disk'] = graph_2_stats_div(stats_disk)
      facts['filemaker_stats_network'] = graph_2_stats_div(stats_network)
   end

   # Always send email when no checks are specified.
   send_email = send_email || ((email_errors == 0) && (email_files == 0) && (comp_list == []))

   if true
      p "send_email",send_email
      p "error_list",error_list
      p "email_errors",email_errors
      p "email_files",email_files
      p "file_count",file_count.to_f
      p "comp_list",comp_list
      p "running_components",running_components
   end

   # Send b/c component(s)s are not online?
   check_failed = check_failed || (comp_list != nil) && ((running_components & comp_list) != comp_list)

p (running_components & comp_list)
p (running_components & comp_list) != comp_list
p check_failed

   # Send b/c enough errors occured?
   if error_list.class == String
      error_count = 1
   else
      error_count = error_list.count
   end

p "error_count",error_count

   check_failed = check_failed || ((email_errors > 0) && (error_count >= email_errors))

p check_failed

   # Send b/c too few files are online?
   check_failed = check_failed || (email_files != 0) && (file_count.to_f < email_files)

p check_failed

   if send_email | check_failed
       #send_email (YAML.dump(facts))
       send_email (facts)
   end
end

