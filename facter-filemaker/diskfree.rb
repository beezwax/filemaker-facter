# FACT: FileMaker Server running components
#
# PURPOSE: List the components that are currently running
#
# NOTES:
#
#   No Windows version at this time.
#
#   Testing looks like this:
#     FACTERLIB="/Users/simon_b/filemaker-facter/facter-filemaker"; facter -d diskfree
#
# HISTORY
#   2017-02-08 simon_b: created file
#   2018-10-05 simon_b: made require path relative
#   2018-10-05 simon_b: added APFS formatted volumes

require_relative 'filemaker/filemaker_utils'


Facter.add('diskfree') do

  # Mac OS Version
  confine :kernel => :darwin

  volumes = []

  setcode do

     # What if APFS, NFS, or SMB?
     raw = `df -g -T hfs,apfs`
     dataRows = raw.lines.to_a[1..-1].join
     dataRows.each_line do |line|
	# df columns are space padded at variable column widths, so we entab the space runs
	# and then split columns into array.
        columns = line.replace_spaces().split("\t")
        volumes.push (columns [0] +" " + columns[1] + " " + columns[2] + " " + columns[4])
     end

     volumes
  end
end
