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
