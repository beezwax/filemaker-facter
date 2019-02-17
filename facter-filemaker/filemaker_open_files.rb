# FACT: FileMaker Server running components
#
# PURPOSE: List the currently open files
#
# NOTES:
#
#   No Windows version at this time.
#
#   Testing looks like this:
#     FACTERLIB="/Users/simon_b/filemaker-facter/facter-filemaker"; facter -d filemaker_open_files
#
# HISTORY
#   2018-10-07 simon_b: created file

require_relative 'filemaker/filemaker_utils'


Facter.add('filemaker_open_files') do

  # Mac OS Version
  confine :kernel => :darwin

  setcode do

     
     # lsof: list everything beloning to fmserverd process but only print file paths.
     # cut: strip the "n"
     # grep: only list FileMaker files
     # sort: sort path lines

     # Must run as either root or fmserver user.
     raw = `/usr/sbin/lsof -Fn -p \`/usr/bin/pgrep fmserverd\` | /usr/bin/cut -c2-| /usr/bin/grep ".fmp12$" | /usr/bin/sort`
     dataRows = raw.lines.to_a[1..-1].join

     dataRows
  end
end
