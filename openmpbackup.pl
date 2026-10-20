#!/usr/bin/perl

# Set these for your situation
my $OMPDIR = "/home/openmpowner/Open.mp";
my $BACKUPDIR = "/home/openmpowner/backups";
my $TARCMD = "/bin/tar czf";
my $VERSION = "1.0.0";

# Init file data
my $MySettings = "$ENV{'HOME'}/.opmbackuprc";
my $BACKUPUSER = "";
my $BACKUPPASS = "";
my $BACKUPSERVER = "";
my $BACKUPPATH = "";
my $DEBUG_MODE = "off";
my $MyEditor = $ENV{'EDITOR'};
if ($MyEditor eq "")
{
	$MyEditor = "/bin/nano";
}
my $DOSNAPSHOT = 0;
my $EditPrefs = "";

#-------------------
# No changes below here...
#-------------------

# Get if they said a option
my $CMDOPTION = shift;

sub ReadConfigFile
{
	# Check for config file
	if (-f $MySettings)
	{
		# Read in settings
		open (my $FH, "<", $MySettings) or die "Could not read default file '$MySettings' $!";
		while (<$FH>)
		{
			chop();
			my ($Command, $Setting) = split(/=/, $_);
			if ($Command eq "backupuser")
			{
				$BACKUPUSER = $Setting;
			}
			if ($Command eq "backuppass")
			{
				$BACKUPPASS = $Setting;
			}
			if ($Command eq "backupserver")
			{
				$BACKUPSERVER = $Setting;
			}
			if ($Command eq "backuppath")
			{
				$BACKUPPATH = $Setting;
			}
			if ($Command eq "debugmode")
			{
				$DEBUG_MODE = $Setting;
			}
		}
		close($FH);
	}
	else
	{
		# Store defaults
		open (my $FH, ">", $MySettings) or die "Could not create default file '$MySettings' $!";
		print $FH "backupuser=\n";
		print $FH "backuppass=\n";
		print $FH "backupserver=\n";
		print $FH "backuppath=\n";
		print $FH "debugmode=off\n";
		close($FH);
		system("$MyEditor $MySettings");
		print "Settings saved - please rerun backup\n";
		exit 0;
	}
}

sub PrintDebugCommand
{
	if ($DEBUG_MODE eq "off")
	{
		return;
	}
	my $PassedString = shift;
	print "About to run:\n$PassedString\n";
	print "Press Enter To Run This:";
	my $entered = <STDIN>;
}

if (defined $CMDOPTION)
{
	if ($CMDOPTION eq "snapshot")
	{
		$DOSNAPSHOT = -1;
	}
}

ReadConfigFile();

print "Open.mp Backup - back up your Open.mp server - version $VERSION\n";
print "============================================================\n";
if ($DOSNAPSHOT == -1)
{
        print "Running Manual Snapshot\n";
}

if (defined $CMDOPTION)
{
        if (($CMDOPTION ne "snapshot") && ($CMDOPTION ne "prefs"))
        {
                print "Unknown command line option: '$CMDOPTION'\nOnly allowed options are 'snapshot' and 'prefs'\n";
                exit 0;
        }
	if ($CMDOPTION eq "prefs")
	{
		system("$MyEditor $MySettings");
                print "Settings saved - please rerun backup\n";
                exit 0;
	}
}

sub SnapShotFunc
{
        print "Backing up Open.mp files: ";
        if (-f "$BACKUPDIR/snapshot.tgz")
        {
                unlink("$BACKUPDIR/snapshot.tgz");
        }
        system("$TARCMD $BACKUPDIR/snapshot.tgz $OMPDIR > /dev/null 2>\&1");
        print "\nBackup Completed.\n";
}

if ($DOSNAPSHOT == -1)
{
        SnapShotFunc();
        exit 0;
}

# Get if they said a option
my $CMDOPTION = shift;
if (defined $CMDOPTION)
{
        if ($CMDOPTION ne "prefs")
        {
                print "Unknown command line option: '$CMDOPTION'\nOnly allowed option is '-prefs'\n";
                exit 0;
        }
}

if ($CMDOPTION ne "")
{
	system("$MyEditor $MySettings");
	print "Settings saved - please rerun backup\n";
	exit 0;
}

if (! -d $BACKUPDIR)
{
	print "Backup dir $BACKUPDIR not found, creating...\n";
	system("mkdir -p $BACKUPDIR");
}
print "Moving existing backups: ";

if (-f "$BACKUPDIR/openmpbackup-5.tgz")
{
	unlink("$BACKUPDIR/openmpbackup-5.tgz")  or warn "Could not unlink $BACKUPDIR/openmpbackup-5.tgz: $!";
}
if (-f "$BACKUPDIR/openmpbackup-4.tgz")
{
	rename("$BACKUPDIR/openmpbackup-4.tgz", "$BACKUPDIR/openmpbackup-5.tgz");
}
if (-f "$BACKUPDIR/openmpbackup-3.tgz")
{
	rename("$BACKUPDIR/openmpbackup-3.tgz", "$BACKUPDIR/openmpbackup-4.tgz");
}
if (-f "$BACKUPDIR/openmpbackup-2.tgz")
{
	rename("$BACKUPDIR/openmpbackup-2.tgz", "$BACKUPDIR/openmpbackup-3.tgz");
}
if (-f "$BACKUPDIR/openmpbackup-1.tgz")
{
	rename("$BACKUPDIR/openmpbackup-1.tgz", "$BACKUPDIR/openmpbackup-2.tgz");
}
print "Done\nCreating Backup: ";
system("$TARCMD $BACKUPDIR/openmpbackup-1.tgz --exclude='/sbbs/ctrl/localspy*.sock' --exclude='/sbbs/ctrl/status.sock' $OMPDIR > /dev/null 2>\&1");
if ($BACKUPSERVER ne "")
{
	print "Offsite backup requested\n";
	print "Copying $BACKUPDIR/openmpbackup-1.tgz to $BACKUPSERVER\n";
	PrintDebugCommand("rsync -avz -e ssh $BACKUPDIR/openmpbackup-1.tgz $BACKUPUSER\@$BACKUPSERVER:$BACKUPPATH\n");
	system ("rsync -avz -e ssh $BACKUPDIR/openmpbackup-1.tgz $BACKUPUSER\@$BACKUPSERVER:$BACKUPPATH");
}

print("Done!\n");
exit 0;
