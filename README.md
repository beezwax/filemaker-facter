# filemaker-facter
Facter custom facts for reporting FileMaker Server statistics and status

The files here implement what are called "custom facts" for Facter based reporting with FileMaker Servers.

The core Facter components must first be installed seperately.

Facter installers can be found at:

	http://downloads.puppetlabs.com/facter/
	http://downloads.puppetlabs.com/mac/

At this time (March 2015) converting scripts to use Facter version 2.4

Minimal crontab entry:

#min    hour    dom    mon    dow    command
0       8,12,16 *      *      *      /usr/bin/facter macosx_productversion memoryfree sp_uptime filemaker_version filemaker_errors | /usr/bin/mail -s "facter report `/bin/hostname`" simon@beezwax.nodomain
