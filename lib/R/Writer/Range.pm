# $Id: /mirror/coderepos/lang/perl/R-Writer/trunk/lib/R/Writer/Range.pm 42797 2008-02-25T07:34:55.014261Z daisuke  $

package R::Writer::Range;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors($_) for qw(start end);

sub new { shift->SUPER::new({ start => $_[0], end => $_[1] }) }

sub as_string
{
    my $self = shift;
    return join(":", $self->start, $self->end);
}

1;
