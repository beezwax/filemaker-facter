#!/usr/bin/ruby

# PURPOSE
# 
# This script can be used to email out the Facter report. Optionally, an email can
# only be sent if certain conditions are met. 
#
# Typical usage would look like this:
#    facter -y | process_and_email --mail simon@beezwax.nodomain,joe@beezwax.nodomain
#
# HISTORY
#
# 2015-04-07 simon_b: created file

require 'optparse'
require 'yaml'
require 'net/smtp'

INCR = 100

def graph_stat_row(stat_row)
   # filemaker_stats_disk => [["2015-04-01 11:37:03.030 -0700", 1649.0, 679.0], ["2015-04-02 11:37:03.346 -0700", 149.0, 318.0], ["2015-04-03 11:37:03.176 -0700", 24.0, 232.0], ["2015-04-04 11:37:03.
   stat_row[1] = "%8d %s" % [stat_row[1], "#" * (stat_row[1] / INCR)]
   stat_row[2] = "%8d %s" % [stat_row[2], "#" * (stat_row[2] / INCR)]
   return stat_row
end

comp_list = []
email_errors = 0
email_files = 0
email_list = []
error_list = []
raw = ""
send_email = false
use_graphs = false

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
      for row in 0..(stats_disk.count - 1)
         stats_disk[row] = graph_stat_row(stats_disk[row])
      end
      for row in 0..(stats_network.count - 1)
         stats_network[row] = graph_stat_row(stats_network[row])
      end
   end

   # Always send email when no checks are specified.
   send_email = send_email | ((error_list == nil) && (email_files == 0) && (comp_list == nil))

   # Send b/c component(s)s are not online?
   send_email = send_email | (comp_list != nil) && ((running_components & comp_list) == comp_list)

   # Send b/c enough errors occured?
   send_email = send_email | (email_errors > 0) && (error_list != nil) && (error_list.count >= email_errors)

   # Send b/c too few files are online?
   send_email = send_email | (email_files > 0) && (file_count >= email_files)

   if send_email
      puts YAML.dump(facts)
   end
end

