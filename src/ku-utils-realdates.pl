# ku-utils-realdates.pl
#
# VERSION: 1.2 (2022-01-21)
#
# __copy1__
# __copy2__
#
# some usefull code snippets that will be "imported" in the main namespace
# if this file is in the include search path, simply include using
#
#	do "ku-utils.pl";
#
# if you place this file in the same dir of the calling program, use
#
#	$_ = $0; s#/[^/]+$##;
#	do "$_/ku-utils.pl";
#
#
# 
# AVAILABLE FUNCTIONS
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
# if you need real dates use "ku-utils-realdates.pl" instad of "ku-utils.pl";
# XXX XXXXXXXXXXXXXXXXXX
#
package main;

our $Verbose	= 1;
our $Debug	= 0;
our %Debug;

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


# --------------------------
# DATE FUNCTIONS (realdates)
# --------------------------
#
use Date::Calc qw( N_Delta_YMDHMS Time_to_Date );


sub ptime
{
	my ($tm) = @_;
	my ($arg_yy,$arg_mo,$arg_dd, $arg_hh,$arg_mm,$arg_ss);

	CASE: {
		if ($tm =~ /^\d+$/) {	# digits only = seconds
			($arg_yy,$arg_mo,$arg_dd, $arg_hh,$arg_mm,$arg_ss) = Time_to_Date( $tm );
			last CASE;
		}
		if ($tm =~ /^\d\d\d\d-\d\d-\d\d$/) {
			($arg_yy,$arg_mo,$arg_dd) = split( '-', $tm );
			($arg_hh,$arg_mm,$arg_ss) = split( ':', "00:00:00" );
			last CASE;
		}
		if ($tm =~ /^\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d/) {
			my ($tmp1,$tmp2) = split( ' ', $tm );
			($arg_yy,$arg_mo,$arg_dd) = split( '-', $tmp1 );
			($arg_hh,$arg_mm,$arg_ss) = split( ':', $tmp2 );
		}
		# last resort, try to convert the string using the date command
		# (pretty sure that a function in Date::Calc package exists, with the same
		# purpouse, but at the moment I'm too lazy to investigate)
		#
		if (!system( "date --date '$tm' >/dev/null 2>/dev/null" )) {
			$tm = `date '+%Y %m %d %H %M %S' --date '$tm'`; chomp($tm);
			($arg_yy,$arg_mo,$arg_dd, $arg_hh,$arg_mm,$arg_ss) = split( ' ', $tm );
			last CASE;
		}
		printf( STDERR "ptime(%s) error: argument must be in seconds, or date YYYY-MM-DD [HH:MM:SS]\n" );
		return;
	}
	pdebug( '', "args: yy=%s mo=%s dd=%s hh=%s mm=%s ss=%s",
		$arg_yy,$arg_mo,$arg_dd, $arg_hh,$arg_mm,$arg_ss );

	my ($now_yy,$now_mo,$now_dd, $now_hh,$now_mm,$now_ss) = Time_to_Date( time() );

        my ($yy,$mo,$dd, $hh,$mm,$ss) = N_Delta_YMDHMS( $arg_yy,$arg_mo,$arg_dd, $arg_hh,$arg_mm,$arg_ss,
							$now_yy,$now_mo,$now_dd, $now_hh,$now_mm,$now_ss );


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
