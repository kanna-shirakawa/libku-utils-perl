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
