# ku-utils.pl
#
# VERSION: 1.4 (2022-04-15)
#
# __copy1__
# __copy2__
#
# some usefull code snippets that will be "imported" in the main namespace
# if this file is in the include search path, simply include using
#
#	do "ku-utils.pl" or die;
#
# if you place this file in the same dir of the calling program, use
#
#	$_ = $0; s#/[^/]+$##;
#	do "$_/ku-utils.pl" or die;
#
# 
# AVAILABLE FUNCTIONS
#
#   tprintf( format, args )
#	return the output of sprintf(), preceeded by timestamp in the format
#	YYYYmmdd HHMMSS; usefull to print logfiles lines
#
#   vprint( message, [args] )
#   	prints message on stdout if $Verbose is not zero; same exact syntax
#   	of printf(),  newline needed
#
#   set_debug_and_verbose( args )
#	scans passed array to detect verbose and debug arguments, and set
#	$Verbose, $Debug and %Debug accordlying; returst the same array
#	without the processed arguments; usually called as
#
#	  @ARGV = set_debug_and_verbose( @ARGV );
#
#	the usual options for verbose and debug are detected, both short
#	and long: -v, --verbose, -q, --quiet, -D, --debug, -Dtag,
#	--debug=tag, -Dtag1,tag2,tag...
#
#   pdebug( tag, message, [args] )
#   	prints message on stderr, precedeed by "D# " string, only if
#	$Debug is true AND $Debug{$tag} is true, or '$tag' is empty/undefined
#
#	same syntax of printf(), but newline is always added
#
#   ptime( seconds )
#   	convert time, expressed in seconds, to a properly formatted string
#   	in the form "years days hours:minutes:seconds"; only the relevant
#	parts of the string are returned, ie:
#
#	  ptime( 59 )		59s
#	  ptime( 125 )		 2:05 (note the space, minutes are aligned)
#	  ptime( 98765 )	1d 3:26:05
#	  ptime( 987654 )	11d 10:20:54
#	  ptime( 987654321 )	31y 108d 10:25:21
#
#   pdate( [time], [long_flag] )
#   	return a formatted date for the passed time, or current if not
#   	passed or empty/undefined; if $long_flag = true will return
#   	the hour also, the default is date only; the date is formmatted
#   	as yyyy-mm-dd (reverse date); ie:
#
#	  pdate()			2021-09-22
#	  pdate( '' )			2021-09-22
#	  pdate( '', 1 )		2021-09-22 11:58:29
#	  pdate( 1234567890, 1 )	2009-01-14 00:31:30
#
#
#
# VARS DECLARATIONS
#
# you NEED to declare $Verbose, $Debug and %Debug variables in your main
# program, using "our", not "my":
#
#	our $Verbose;
#	our $Debug;
#	our %Debug;
#
# %Debug contains the tags used by 'pdebug()' function to select what message
# needs to be printed or not; the hash is populated when you pass the options
# in the form "-Dtag" or "--debug=tag", but you can populate the %Debug in
# your main program, so the LIST action (-DLIST) become usefull
#
# environment $VERBOSE and $DEBUG will overrides the defaults, but command
# line options will have the precedence
#
# environtment $DEBUGLEVEL will override $Debug, too
#
#
# SIMPLE DATES VS REAL DATES
#
# date print functions are simple and not accurate, usable when precision is
# not a requirement; the cons are that you don't need any additional perl
# module to use them
#
# if you need real dates use "ku-utils-realdates.pl" instead of "ku-utils.pl";

# pollution!
package main;

our $Verbose	= 1;
our $Debug	= 0;
our %Debug;

sub tprintf
{
	my $fmt = shift;
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	my $out = sprintf( "%4d%02d%02d %02d%02d%02d ",
			$year+1900, $mon+1, $mday, $hour, $min, $sec );

	$out .= sprintf( $fmt, @_ );
	return $out;
}

sub vprint
{
	return	1	if (!$Verbose);
	my $fmt	= shift(@_);
	printf( $fmt, @_ );
	return 1;
}

sub set_debug_and_verbose
{
	my $arg;
	my @left;

	# set defaults from environment, if any
	#
	if (defined $ENV{VERBOSE}) {
		##printf( STDERR "DD# env \$VERBOSE='%s'\n", $ENV{VERBOSE} );
		if ($ENV{VERBOSE} eq "true") {
			$Verbose = 1;
		} else {
			$Verbose = 0;
		}
	}
	if (defined $ENV{DEBUG}) {
		##printf( STDERR "DD# env \$DEBUG='%s'\n", $ENV{DEBUG} );
		if ($ENV{DEBUG} eq "true") {
			$Debug = 1;
		} else {
			$Debug = 0;
		}
	}
	if (defined $ENV{DEBUGLEVEL}) {
		##printf( STDERR "DD# env \$DEBUGLEVEL='%s'\n", $ENV{DEBUGLEVEL} );
		foreach $_ (split(',',$ENV{DEBUGLEVEL})) {
			$Debug{$_} = 1;
		}
	}

	while (scalar(@_)) {
	    $arg = shift(@_);
	    CASE: {
		if ($arg eq "-v" || $arg eq "--verbose")	{ $Verbose = 1; last CASE; }
		if ($arg eq "-q" || $arg eq "--quiet")		{ $Verbose = 0; last CASE; }
		if ($arg eq "-D" || $arg eq "--debug")		{ $Debug = 1; last CASE; }
		if ($arg eq "-DL" || $arg  eq "--debug=LIST") {
			print( STDERR "\ndebug keywords usable with --debug (-D) option:\n\n" );
			print( STDERR "  LIST  (prints this list)\n" );
			foreach $_ (sort keys(%Debug)) {
				print( STDERR "  $_\n" );
			}
			exit( 0 );
		}
		if ($arg =~ /^-D[a-z]/ || $arg =~ /^--debug=[a-z]/) {
			$Debug = 1;
			$arg =~ s/^-D//; $arg =~ s/^--debug=//;
			foreach $_ (split(',',$arg)) {
				$Debug{$_} = 1;
			}
			last CASE;
		}
		push( @left, $arg );
	    }
	}
	return @left;
}


sub pdebug
{
	return 1	if (!$Debug);
	my $tag = shift(@_);
	my $fmt = shift(@_);
	my $msg = sprintf( $fmt, @_ );
	if (defined $tag && $tag ne "") {
		return 1	if (!defined $Debug{$tag} || !$Debug{$tag});
	}
	printf( STDERR "D# %s\n", $msg );
	return 1;
}


# ----------------------------
# DATE FUNCTIONS (simpledates)
# ----------------------------
#
# inaccurate, but don't uses additional modules
#
sub ptime
{
	my ($tm) = @_;
	my ($yy,$mo,$dd);
	my ($hh,$mm,$ss);
	my ($out,$left);

	CASE: {
		if ($tm =~ /^\d+$/) {	# digits only = seconds
			last CASE;
		}
		if (!system( "date --date '$tm' >/dev/null 2>/dev/null" )) {
			$tm = `date '+%s' --date '$tm'`; chomp($tm);
			$tm = time() - $tm;
			last CASE;
		}
		printf( STDERR "ptime(%s) error: argument must be in seconds, or a valid date\n" );
		return;
	}
	pdebug( '', "args: tm=%s", $tm );

	$yy	= int( $tm / 31557600 );	# secs x year
	$left	= $tm - $yy * 31557600;
	$mo	= int( $left / 2628000 );	# secs x month (media)
	$left	= $left - $mo * 2628000;
	$dd	= int( $left / 86400 );		# secs x day
	$left	= $left - $dd * 86400;
	$hh	= int( $left / 3600 );		# secs x hour
	$left	= $left - $hh * 3600;
	$mm	= int( $left / 60);		# secs x minute
	$ss	= $left - $mm * 60;
	if ($yy) {
		$out = sprintf( "%dy %dm %dd %d:%02d:%02d", $yy, $mo, $dd, $hh, $mm, $ss );
	} elsif ($mo) {
		$out = sprintf( "%dm %dd %d:%02d:%02d", $mo, $dd, $hh, $mm, $ss );
	} elsif ($dd) {
		$out = sprintf( "%dd %d:%02d:%02d", $dd, $hh, $mm, $ss );
	} elsif ($hh) {
		$out = sprintf( "%2d:%02d:%02d", $hh, $mm, $ss );
	} elsif ($mm) {
		$out = sprintf( "%2d:%02d", $mm, $ss );
	} else {
		$out = $ss . "s";
	}
	return $out;
}

sub pdate
{
	my ($tm,$long) = @_;
	my (@tm,$out);

	$tm = time()	if (!defined $tm || $tm eq "");
	@tm = localtime($tm);

	$out = sprintf( "%d-%02d-%02d", $tm[5]+1900, $tm[4]+1, $tm[3] );

	if (defined $long && $long) {
		$out .= sprintf( " %02d:%02d:%02d", $tm[2], $tm[1], $tm[0] );
	}
	return $out;
}

1;
