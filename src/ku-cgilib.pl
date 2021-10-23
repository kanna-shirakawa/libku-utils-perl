# ../cgi-bin/cglib.pl
#
# (c) Lorenzo Canovi (KUBiC Labs, CH) <packager@kubiclabs.com>
# for copyright see /usr/share/doc/kubackup/copyright
#
# really, taken from internet years ago and modified, don't know exactly where
# and who's the original author
#
#
# Read all CGI vars into an associative array.
# If multiple input fields have the same name, they are concatenated into
#   one array element and delimited with the \0 character (which fails if
#   the input has any \0 characters, very unlikely but conceivably possible).
# Currently only supports Content-Type of application/x-www-form-urlencoded.

sub getcgivars {
    local($in, %in) ;
    local($name, $value) ;

    # debug, if the script if called via command line, emulate a GET req
    #
    if (!defined $ENV{'REQUEST_METHOD'}) {
	    $ENV{'SCRIPT_NAME'}		= "(DEBUG)";
	    $ENV{'REQUEST_METHOD'}	= "GET";
	    $ENV{'QUERY_STRING'}	= "" . join( "&", @ARGV );
	    $ENV{'DEBUG'}		= "true";
	    print( STDERR "(DEBUG) emulate GET request, query='"
		    . $ENV{'QUERY_STRING'} . "'\n" );
    }

    # First, read entire string of CGI vars into $in
    if ( ($ENV{'REQUEST_METHOD'} eq 'GET') ||
         ($ENV{'REQUEST_METHOD'} eq 'HEAD') ) {
        $in= $ENV{'QUERY_STRING'} ;

    } elsif ($ENV{'REQUEST_METHOD'} eq 'POST') {
        if ($ENV{'CONTENT_TYPE'}=~ m#^application/x-www-form-urlencoded$#i) {
            length($ENV{'CONTENT_LENGTH'})
                || &HTMLdie("No Content-Length sent with the POST request.") ;
            read(STDIN, $in, $ENV{'CONTENT_LENGTH'}) ;

        } else { 
            &HTMLdie("Unsupported Content-Type: $ENV{'CONTENT_TYPE'}") ;
        }

    } else {
        &HTMLdie("Script was called with unsupported REQUEST_METHOD.") ;
    }
    
    # Resolve and unencode name/value pairs into %in
    foreach (split(/[&;]/, $in)) {
        s/\+/ /g ;
        ($name, $value)= split('=', $_, 2) ;
        $name=~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge ;
        $value=~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge ;
        $in{$name}.= "\0" if defined($in{$name}) ;  # concatenate multiple vars
        $in{$name}.= $value ;
    }

    return %in ;

}


# html output helpers

sub HTMLhead {
	local( $title, $meta, $bodyparms )= @_ ;
	my $buf;

	$title	= $ENV{HTTP_HOST}	if (!defined $title);

	$buf .= "Content-type: text/html\n\n";
	$buf .= "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\"\n";
	$buf .= "  \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">\n";
	$buf .= "<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\" lang=\"en\">\n";
	$buf .= "<head>\n";
	$buf .= sprintf( " <title>%s</title>\n", $title );
	$buf .= sprintf( " %s\n", $meta )	if (defined $meta);
	$buf .= "</head>\n";
	if (defined $bodyparms) {
		$buf .= sprintf( "<body %s>\n", $bodyparms );
	} else {
		$buf .= "<body>\n";
	}
	print( $buf );
}

sub HTMLdie {
	local $msg	= shift( @_ );
	local $title;
	if (scalar(@_) > 0) {
		$title	= shift( @_ );
	} else {
		$title	= "CGI Error";
	}

	HTMLhead( @_ );
	print( "<h1>$title</h1>\n" );
	print( "<h3>$msg</h3>\n" );
	print( STDERR $msg . "\n" );
	print( "</body></html>\n" );
	exit( 1 );
}

sub HTMLoutpage {
	local $buf	= shift( @_ );
	HTMLhead( @_ );
	print( $buf );
	print( "</body></html>\n" );
	return 1;
}

1;
