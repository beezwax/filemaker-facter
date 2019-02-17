![Beezwax Logo](https://blog.beezwax.net/wp-content/uploads/2016/01/beezwax-logo-github.png)

# filemaker-facter
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/beezwax/filemaker-facter/blob/master/LICENSE)

Facter custom facts for reporting FileMaker Server statistics and status.

The files here implement what are called "custom facts" for Facter based reporting with FileMaker Servers. Additionally, there is a helper script that can email alerts when certain conditions are met.

Currently working facts are:

| Fact Name               | Description |
|-------------------------|-------------|
| diskfree                | lists volumes, space used (GB), space free (GB), and used space (percentage) |
| filemaker_components    | FileMaker server components currently running |
| filemaker_errors        | recent errors in the Events.log (if any) |
| filemaker_file_count    | number of open database files on server |
| filemaker_open_files    | paths of currently open database files |
| filemaker_stats_disk    | disk usage for week, broken down by 24-hour period |
| filemaker_stats_elapsed    | sum of elapsed time (seconds) for week, broken down by 24-hour period |
| filemaker_stats_io_time    | sum of I/O times (seconds) for week, broken down by 24-hour period |
| filemaker_stats_network | network bytes for week, broken out by 24-hour period |
| filemaker_version       | version of FileMaker Server |

At this time (Oct 2018) scripts are tested with Facter version 2.5.1

## Installation & Configuration

The core Facter components must first be installed separately.

Although older Facter installer packages can be found at http://downloads.puppetlabs.com, Facter 2.x is best installed using the **gem** command, which on macOS looks like:
```
sudo gem install facter
```
You may want to first do a ```sudo gem update```. For macOS this will require the XCode Command Line Tools. You may be able to install this using the command ```xcode-select --install```, or download installer from Apple's Developer site.

With the core facter install complete, download the FileMaker custom facts from the filemaker-facter's main GitHub page by choosing **Download Zip** under the **Clone or download** button.
Inside the **filemaker-facter** folder from the zip file, copy the **facter-filemaker** folder to ```/usr/local/lib``` (macOS) or ```C:\Ruby25-x64\lib\ruby\gems\2.5.0\gems\facter-2.5.1-x64-mingw32\lib\facter``` folder (Windows). You may need to create the folder at ```/usr/local/lib``` first.

Error event settings can be adjusted in the file at **filemaker/filemaker_utils.rb** to control maximum number of errors reported and how far back in logs to search for errors.

For some functions to work, **Usage Statistics** logging must be enabled in the FileMaker Server Admin Console. For FileMaker 16, you can find this in the Logging panel in the Database Server section, then checking the **Usage statistics** option. For FileMaker 17, you must use the fmsadmin command: ```fmsadmin enable serverstats```

## Crontab Example

On OS X systems, a crontab entry is a convenient way to send regular reports.

Here, we assume email (typically Postfix SMTP) is configured on the local system. Enabling Mail with Server.app will accomplish this, or search online for how to configure a Postfix STMP relay. When enabled, this allows us to use the **mail** command to pipe out the reports.

As part of the crontab entry example, the specific facters we want in the report are listed (if none are specified after the ```facter``` command all facts are included).

```
# Location of our custom facts.
FACTERLIB=/usr/local/lib/facter-filemaker
#
#min    hour    dom    mon    dow    command
#
# Send report on Sunday at one minute past midnight.
0       0       *      *      0      /usr/local/bin/facter macosx_productversion diskfree memoryfree sp_uptime filemaker_errors filemaker_stats_disk filemaker_version | /usr/bin/mail -s "facter report: `/bin/hostname`" simon@beezwax.yourdomain
```

## process_and_email.rb

For additional functionality, including some basic monitoring functions, there is a helper script written in Ruby you can use inside of **facter-filemaker/filemaker** folder. This script does post-processing of the Facter reports, and provides the following features:

* send via SMTP client (no need to configure Postfix)
* convert disk & network stats into graph
* send email when more than x errors are found
* send email if required components are not running
* send email if too few files are online

### Configuration

In order for the email feature to work, you must edit the script to set various email related variables.

* E_DOMAIN: domain name for server's email
* E_TOS: email addresses to send reports and alerts to
* E_SMTP: host name of SMTP server to use
* E_PORT: port number to use for SMTP connection (if you need to use encryption or authentication you will have to modify the send_email function)

### Parameters

The process_and_email command accepts four parameters used to set how results are returned and values to check for.

* **--always-email** Always send message, useful for status emails
* **--components name[,...]** If the named components are not running email is sent
  - component names are: ADMINSERVER, FMSIB, SERVER, WPE, XDBC, fmserver_helperd, httpd, fmslogtrimmer
* **--elapsed seconds** Send  email if at elapsed wait time over **microseconds**
* **--errors count** Send  email if at least **count** recent errors
* **--files count** Send email if less then **count** files are open
* **--graph** Enable graphing of stats
* **--uptime minutes** Send  email if uptime is less then **minutes**

**Usage Examples**

Email selected facts, graphing the stats:
```
/usr/local/bin/facter -y macosx_productversion diskfree memoryfree sp_uptime filemaker_version filemaker_components filemaker_errors filemaker_file_count filemaker_stats_disk filemaker_stats_network | /Library/Ruby/Site/facter/filemaker/process_and_email.rb -a --graph
```

Email if the specified components are not running, fewer then 20 files are online, or more then 5 errors in log:
```
/usr/local/bin/facter -y | /usr/local/lib/facter-filemaker/filemaker/process_and_email.rb --graph --components ADMINSERVER,FMSE,SERVER,WPE,httpd --files 20 --errors 5
```

Below shows a crontab example to perform two tasks. First, on first day of month always email a report a brief selection of facts. Second, check every hour if:

* ADMINSERVER, FMSE, SERVER, WPE, and httpd processes are running
* at least two database files are open
* elapsed wait time has not exceeded 2000 ms
* uptime is less than 60 minutes (the default)

```
# Location of our custom facts. These are added in to the standard ones.
FACTERLIB=/usr/local/lib/facter-filemaker
#
#min    hour    dom    mon    dow    command
0       0       1      *      *      /usr/local/bin/facter -y | /usr/local/facter-filemaker/filemaker/process_and_email.rb -a --graph
1       *       *      *      *      /usr/local/bin/facter -y diskfree memoryfree sp_uptime filemaker_version filemaker_components filemaker_errors filemaker_file_count filemaker_stats_disk filemaker_stats_network | /usr/local/lib/facter-filemaker/filemaker/process_and_email.rb --graph --components ADMINSERVER,FMSE,SERVER,WPE,httpd --files 2 --errors 2 --elapsed 2000 --uptime
```

This script is still a work in progress, so check the script source for current information on usage & abilities.

- - -
<h6>Built by <a href="http://beezwax.net">Beezwax</a</h6>
