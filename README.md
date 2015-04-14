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
When the install is complete, copy the **contents** of the **copy_to_facter** folder into facter's folder. With the installer image, this will be the **/Library/Ruby/Site/facter** folder (Mac OS) or **C:\Program Files\Puppet Labs\Puppet\facter\lib\facter** folder (Windows).

At this time (April 2015) scripts are tested with Facter version 2.4.3


crontab usage example:
```
#min    hour    dom    mon    dow    command
0       8,12,6  *      *      *      /usr/bin/facter macosx_productversion memoryfree sp_uptime filemaker_version filemaker_errors filemaker_stats_disk | /usr/bin/mail -s "facter report: `/bin/hostname`" simon@beezwax.nodomain
```

###process_and_email.rb
This script can be found inside copy_to_facter/filemaker folder. By post-processing the Facter reports it provides a number of features:
* convert disk & network stats into graph
* send email when more than x errors are found
* send email if required components are not running
* send email if too few files are online

Parameters are:
* **--components name[,...]** If the named components are not running email is sent
..* component names are: ADMINSERVER, FMSIB, SERVER, WPE, XDBC, fmserver_helperd, httpd, fmslogtrimmer
* **--errorsSend count** Send  email if at least **count** recent errors
* **--files count** Send email if less then **count** files are open
* **--graph** Enable graphing of stats

This script is still a work in progress, so See the script for current information on usage & abilities.
