package R::Writer::Util;
use strict;
use warnings;

sub __R
{
    # Return the top-most $_[0] R::Writer object in stack.
    my $level = 3;
    my @c = ();
    my $r;
    while ( $level < 10 && (!defined($c[3]) || $c[3] eq '(eval)') ) {
        @c = do {
            package DB;
            @DB::args = ();
            caller($level);
        };
        $level++;

        if (ref($DB::args[0]) eq 'R::Writer') {
            $r = $DB::args[0] ;
            last;
        }
    }
    return $r;
}

sub __IN_RWRITER_PACKAGES__
{
    my $level = 0;
    my @c = caller(++$level);
    while ( @c > 0 ) {
        return 1 if defined $c[0] && index($c[0], 'R::Writer') == 0;
        @c = caller(++$level);
    }
    return 0;
}

1;
