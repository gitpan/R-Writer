# $Id: /mirror/coderepos/lang/perl/R-Writer/trunk/lib/R/Writer/Encoder.pm 42804 2008-02-25T10:17:18.239702Z daisuke  $

package R::Writer::Encoder;
use strict;
use warnings;

use JSON::XS (); # XXX - Remove this in the future?
our $CODER = JSON::XS->new->allow_nonref;

sub new    { bless \my $c, shift }
sub encode { $CODER->encode($_[1]) }

1;
