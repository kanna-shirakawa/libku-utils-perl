# --------------------------
# DATE FUNCTIONS (realdates)
# --------------------------
#
use Date::Calc qw( N_Delta_YMDHMS Time_to_Date );

sub ptime
{
	my ($tm) = @_;
	my ($arg_yy,$arg_mo,$arg_dd, $arg_hh,$arg_mm,$arg_ss);
	my ($tmp);

	CASE: {
		if ($tm =~ /^\d+$/) {	# digits only = seconds
			$tm = time() - $tm;
			pdebug( '', "ptime(): using Time_to_Date(%s)", $tm );
			($arg_yy,$arg_mo,$arg_dd, $arg_hh,$arg_mm,$arg_ss) = Time_to_Date( $tm );
			last CASE;
		}
		if ($tm =~ /^\d\d\d\d-\d\d-\d\d$/) {
			pdebug( '', "ptime(): using short date YYYY-mm-dd" );
			($arg_yy,$arg_mo,$arg_dd) = split( '-', $tm );
			($arg_hh,$arg_mm,$arg_ss) = split( ':', "00:00:00" );
			last CASE;
		}
		if ($tm =~ /^\d\d\d\d-\d\d-\d\d \d\d:\d\d$/) {
			pdebug( '', "ptime(): using long date YYYY-mm-dd HH:MM" );
			my ($tmp1,$tmp2) = split( ' ', $tm );
			($arg_yy,$arg_mo,$arg_dd) = split( '-', $tmp1 );
			($arg_hh,$arg_mm) = split( ':', $tmp2 );
			$arg_ss = 0;
			last CASE;
		}
		if ($tm =~ /^\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d$/) {
			pdebug( '', "ptime(): using long date YYYY-mm-dd HH:MM:SS" );
			my ($tmp1,$tmp2) = split( ' ', $tm );
			($arg_yy,$arg_mo,$arg_dd) = split( '-', $tmp1 );
			($arg_hh,$arg_mm,$arg_ss) = split( ':', $tmp2 );
			last CASE;
		}
		# last resort, try to convert the string using the date command
		# (pretty sure that a function in Date::Calc package exists, with the same
		# purpouse, but at the moment I'm too lazy to investigate)
		#
		if (!system( "date --date '$tm' >/dev/null 2>/dev/null" )) {
			pdebug( '', "ptime(): last resort, using 'date' command" );
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
	pdebug( '', "now:  yy=%s mo=%s dd=%s hh=%s mm=%s ss=%s",
		$now_yy,$now_mo,$now_dd, $now_hh,$now_mm,$now_ss );

        my ($yy,$mo,$dd, $hh,$mm,$ss) = N_Delta_YMDHMS( $arg_yy,$arg_mo,$arg_dd, $arg_hh,$arg_mm,$arg_ss,
							$now_yy,$now_mo,$now_dd, $now_hh,$now_mm,$now_ss );
	pdebug( '', "diff: yy=%s mo=%s dd=%s hh=%s mm=%s ss=%s",
		$yy,$mo,$dd, $hh,$mm,$ss );

	# for same reason N_Delta_YMDHMS() returns crazy values in some circustances; ie tested
	# on 2022-03-06 17:11:05, with those input values we got:
	#
	#	input = 41608h	-> 4y 8m 27d 16:00:00
	#	input = 41609h	-> 3y 19m 58d 17:00:00	WTF?
	#
	# as workaround we recalculate timediff subtracting 1 hour to the input value (here,
	# adding 1 hour to the difference), and then normalizing the result
	#
	# note that this workaround can returns wrong H value (but I can't test it, since the input
	# conditions that trigger the incorrect beheaviour and the workaround  are almost random)
	#
	$tmp = 0;
	while ($mo > 12 || $dd > 31) {
		$tm += 3600;
		$tmp ++;
		pdebug( '', "wrong values returned, trying workaround, adding %d hours to input", $tmp );

		($arg_yy,$arg_mo,$arg_dd, $arg_hh,$arg_mm,$arg_ss) = Time_to_Date( $tm );
		pdebug( '', "wk args: yy=%s mo=%s dd=%s hh=%s mm=%s ss=%s",
			$arg_yy,$arg_mo,$arg_dd, $arg_hh,$arg_mm,$arg_ss );

        	($yy,$mo,$dd, $hh,$mm,$ss) = N_Delta_YMDHMS( $arg_yy,$arg_mo,$arg_dd, $arg_hh,$arg_mm,$arg_ss,
							     $now_yy,$now_mo,$now_dd, $now_hh,$now_mm,$now_ss );
		$hh -= $tmp;
		pdebug( '', "wk diff: yy=%s mo=%s dd=%s hh=%s mm=%s ss=%s", $yy,$mo,$dd, $hh,$mm,$ss );
	}


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
