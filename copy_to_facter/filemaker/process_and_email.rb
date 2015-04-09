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
require 'yaml'
require 'net/smtp'
require 'socket'

# GLOBAL CONSTANTS
#
INCR = 200

# email settings

HOSTNAME = Socket.gethostname

# TODO: Use a YAML file for this.
#
E_DOMAIN = "beezwax.net"
E_FROM = HOSTNAME + "@" + E_DOMAIN
E_TOS = ["simon_b@beezwax.net"]
E_SUBJECT = "Facter Report: " + HOSTNAME + "." + E_DOMAIN
#E_SMTP = "mail.beezwax.net"
E_SMTP = "localhost"
E_PORT = 25

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

def graph_stat_rows (stat_rows)
   graph = '<div class="chart">'

   for row in 0..(stats_row.count - 1)
      stats_disk[row] = graph_stat_row(stats_disk[row])
   end

end

#
#  s e n d _ e m a i l
#

def send_email (body)

   puts E_SMTP
   puts E_DOMAIN
   puts E_SUBJECT
   puts E_FROM
   puts E_TOS

   body_brd = body.gsub(/\n/, "<br>\n")
   puts body_brd
  puts

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
         f.puts '.chrd div { font: 10px sans-serif; background-color: steelblue; text-align: right; padding: 3px; margin: 1px; color: white; }'
         f.puts '.chwr div { font: 10px sans-serif; background-color: red; text-align: right; padding: 3px; margin: 1px; color: white; }'
         f.puts '</style>'
         f.puts '<div class="chrd">  <div style="width: 40px;">4</div> <div style="width: 80px;">8</div> </div>'
         f.puts '<div class="chwr">  <div style="width: 40px;">4</div> <div style="width: 80px;">8</div> </div>'
         f.puts body_brd
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
   error_list = facts['filemaker_errors']
   file_count = facts['filemaker_file_count']
   stats_disk = facts['filemaker_stats_disk']
   stats_network = facts['filemaker_stats_network']

   # When using graphing, we replace the existing numeric values with a string
   # containing the numeric value and an ASCII graph.

   if use_graphs
      stats_disk = graph_2_stats_ascii(stats_disk)
      stats_network = graph_2_stat_ascii(stats_network)
   end

   # Always send email when no checks are specified.
   send_email = send_email || ((error_list == nil) && (email_files == nil) && (comp_list == nil))

send_email = true

   puts "---",error_list,email_files,comp_list,"---"

   # Send b/c component(s)s are not online?
   check_failed = check_failed || (comp_list != nil) && ((running_components & comp_list) != comp_list)

   # Send b/c enough errors occured?
   check_failed = check_failed || (email_errors > 0) && (error_list != nil) && (error_list.count >= email_errors)

   # Send b/c too few files are online?
   check_failed = check_failed || (email_files != nil) && (file_count.to_f < email_files)

   if send_email | check_failed
       send_email (YAML.dump(facts))
   end
end

