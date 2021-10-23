# some usefull code snippets that will be "imported" in the main namespace
# if this file is in the include search path, simly include using
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


sub ptime
{
	my ($tm) = @_;
	my ($hh,$mm,$ss,$out);
	my ($yy,$dd);
	my $left;

	$yy	= int( $tm / 31557600 );	# secs x year
	$left	= $tm - $yy * 31557600;
	$dd	= int( $left / 86400 );		# secs x day
	$left	= $left - $dd * 86400;
	$hh	= int( $left / 3600 );		# secs x hour
	$left	= $left - $hh * 3600;
	$mm	= int( $left / 60);		# secs x minute
	$ss	= $left - $mm * 60;
	if ($yy) {
		$out = sprintf( "%dy %dd %d:%02d:%02d", $yy, $dd, $hh, $mm, $ss );
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

	$out = sprintf( "%d-%02d-%02d", $tm[5]+1900, $tm[4], $tm[3] );

	if (defined $long && $long) {
		$out .= sprintf( " %02d:%02d:%02d", $tm[2], $tm[1], $tm[0] );
	}
	return $out;
}

1;
