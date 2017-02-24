![Beezwax Logo](https://blog.beezwax.net/wp-content/uploads/2016/01/beezwax-logo-github.png)

# filemaker-facter
Facter custom facts for reporting FileMaker Server statistics and status

The files here implement what are called "custom facts" for Facter based reporting with FileMaker Servers. Additionally, there is a helper script that can email alerts when certain conditions are met.

Currently working facts are:

| Fact Name               | Description |
|-------------------------|-------------|
| diskfree                | lists volumes, space used (GB), space free (GB), and used space (percentage) |
| filemaker_components    | FileMaker server components currently running |
| filemaker_errors        | recent errors in the Events.log (if any) |
| filemaker_file_count    | number of open database files on server |
| filemaker_stats_disk    | disk usage for week, broken down by 24-hour period |
| filemaker_stats_elapsed    | sum of elapsed time for week, broken down by 24-hour period |
| filemaker_stats_network | network bytes for week, broken out by 24-hour period |
| filemaker_version       | version of FileMaker Server |

At this time (Feb 2017) scripts are tested with Facter version 2.4.6

## Installation & Configuration

The core Facter components must first be installed separately.

Facter installers can be found at:

* http://downloads.puppetlabs.com/mac/
* http://downloads.puppetlabs.com/windows/

Facter can often also be installed using the **gem** command:
```
sudo gem install facter
```
When the install is complete, copy the _contents_ of the **copy_to_facter** folder into facter's folder. With the installer image, this will be the **/Library/Ruby/Site/facter** folder (Mac OS) or **C:\Program Files\Puppet Labs\Puppet\facter\lib\facter** folder (Windows).

Error event settings can be adjusted in the file at **facter/filemaker/filemaker_utils.rb**.

For some functions to work, **Usage Statistics** logging must be enabled in the FileMaker Server Admin Console. You can find this in the Logging panel in the Database Server section, then checking the **Usage statistics** option.

## Crontab Example

On OS X systems, a crontab entry is a convenient way to send regular reports.

Here, we assume email (typically Postfix SMTP) is configured on the local system. Enabling Mail with Server.app will accomplish this, or search online for how to configure a Postfix STMP relay. When enabled, this allows us to use the **mail** command to pipe out the reports. Additionaly, in the crontab entry example, the specific facters we want in the report are listed (if these are omitted all values are included).

```
#min    hour    dom    mon    dow    command
0       8,12,6  *      *      *      /usr/bin/facter macosx_productversion memoryfree sp_uptime filemaker_errors filemaker_stats_disk filemaker_version | /usr/bin/mail -s "facter report: `/bin/hostname`" simon@beezwax.nodomain
```

##process_and_email.rb

For additional functionality, including some basic monitoring functions, there is a helper script you can use inside of **copy_to_facter/filemaker** folder. This script does post-processing of the Facter reports, and provides the following features:
* send via SMTP client (no need to configure Postfix)
* convert disk & network stats into graph
* send email when more than x errors are found
* send email if required components are not running
* send email if too few files are online

### Configuration

In order for the email feature to work, you must edit the script to set various email related variables.

* E_DOMAIN: domain name for server's email
* E_TOS: email addresses to send email to
* E_SMTP: host name of SMTP server to use
* E_PORT: port number to use for SMTP connection (if you need to use encryption or authentication you will have to modify the send_email function)

### Parameters

The process_and_email command accepts four parameters used to set how results are returned and values to check for.

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
  - specify email related parameters from command line or file
* return count of recent WebDirect clients
* return count of recent FMP clients

- - -
<h6>Built by <a href="http://beezwax.net">Beezwax</a</h6>
