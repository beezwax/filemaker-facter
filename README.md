# filemaker-facter
Facter custom facts for reporting FileMaker Server statistics and status

The files here implement what are called "custom facts" for Facter based reporting with FileMaker Servers. Additionally, there is a helper script that email alerts when certain conditions are met.

Currently working facts are:

| Fact Name               | Description |
|-------------------------|-------------|
| filemaker_components    | FileMaker server components currently running |
| filemaker_errors        | recent errors in the Events.log (if any) |
| filemaker_file_count    | number of open database files on server |
| filemaker_stats_disk    | disk usage for week, broken down by 24-hour period |
| filemaker_stats_network | network bytes for week, broken out by 24-hour period |
| filemaker_version       | version of FileMaker Server |

The core Facter components must first be installed seperately.

Facter installers can be found at:

http://downloads.puppetlabs.com/mac/
http://downloads.puppetlabs.com/windows/

Facter can often also be installed using the **gem** command:
```
sudo gem install facter
```
When the install is complete, copy the _contents_ of the **copy_to_facter** folder into facter's folder. With the installer image, this will be the **/Library/Ruby/Site/facter** folder (Mac OS) or **C:\Program Files\Puppet Labs\Puppet\facter\lib\facter** folder (Windows).

At this time (April 2015) scripts are tested with Facter version 2.4.3


crontab usage example:
```
#min    hour    dom    mon    dow    command
0       8,12,6  *      *      *      /usr/bin/facter macosx_productversion memoryfree sp_uptime filemaker_version filemaker_errors filemaker_stats_disk | /usr/bin/mail -s "facter report: `/bin/hostname`" simon@beezwax.nodomain
```

###process_and_email.rb
This script can be found inside **copy_to_facter/filemaker** folder. By post-processing the Facter reports it provides a number of features:
* convert disk & network stats into graph
* send email when more than x errors are found
* send email if required components are not running
* send email if too few files are online

In order for the email feature to work, you must edit the script to set various email related variables.

Parameters are:
* **--components name[,...]** If the named components are not running email is sent
  - component names are: ADMINSERVER, FMSIB, SERVER, WPE, XDBC, fmserver_helperd, httpd, fmslogtrimmer
* **--errors count** Send  email if at least **count** recent errors
* **--files count** Send email if less then **count** files are open
* **--graph** Enable graphing of stats

**Usage Examples**
Email selected facts, graphing the stats:
```
/usr/bin/facter -y macosx_productversion memoryfree sp_uptime filemaker_version filemaker_components filemaker_errors filemaker_file_count filemaker_stats_disk filemaker_stats_network | /Library/Ruby/Site/facter/filemaker/process_and_email.rb --graph
```

Email if the specified components are not running, fewer then 20 files are online, or more then 5 errors in log:
```
/usr/bin/facter -y | /Library/Ruby/Site/facter/filemaker/process_and_email.rb --graph --components ADMINSERVER,FMSE,SERVER,WPE,httpd --files 20 --errors 5
```

This script is still a work in progress, so See the script for current information on usage & abilities.

###TO-DO'S
* process_and_email
  - handle incorrectly formatted or missing data better
  - allow specifying graph step amount
  - specify email related parameters from command line or file
* return recent wait times
* check for high wait times
* return count of recent WebDirect clients
* return count of recent FMP clients
