# $Id: /mirror/coderepos/lang/perl/R-Writer/trunk/lib/R/Writer.pm 42855 2008-02-26T07:09:17.275444Z daisuke  $

package R::Writer;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
use R::Writer::Encoder;
use R::Writer::Range;
use R::Writer::Var;
use R::Writer::Util;

__PACKAGE__->mk_accessors($_) for qw(encoder);

our $VERSION = '0.00001';
use Sub::Exporter -setup => {
    exports => [ 'R' ]
};

my $base;

sub append {
    my $self = shift;

    if ( R::Writer::Util::__IN_RWRITER_PACKAGES__ ) {
        push @{ $self->{statements} }, { code => shift };
        return $self;
    }

    return $self->call("append", @_);
}


sub R
{
    my $R = R::Writer::Util::__R();
    my ($obj) = @_;

    if (defined $R) {
        $R->{object} = $obj if defined $obj;
        return $R;
    }

    $base = R::Writer->new(@_) unless defined $base;
    $base->{object} = $obj if defined $obj;
    return $base;
}

sub new
{
    my $class = shift;
    my $self = $class->SUPER::new({
        encoder    => R::Writer::Encoder->new,
        @_,
        statements => [],
        delimiter  => undef,
    });
    return $self;
}

sub call
{
    my ($self, $function, @args) = @_;

    push @{$self->{statements}}, {
        object => delete $self->{object} || undef,
        call   => $function,
        args   => \@args,
        end_of_call_chain => ! defined wantarray
    };
    return $self;
}

# XXX - This looks fishy
sub range
{
    my ($self, $start, $end) = @_;
    my $obj = R::Writer::Range->new($start, $end);
#    $self->append($obj->as_string, delimiter => "");
    $obj;
}

sub obj_as_string
{
    my ($self, $obj) = @_;

    my $ref = ref($obj);

    if ($ref eq 'CODE') {
        return $self->function($obj);
    }
    elsif ($ref =~ /^R::Writer/) {
        return $obj->as_string
    }
    elsif ($ref eq "SCALAR") {
        return $$obj
    }
    elsif ($ref eq 'ARRAY') {
        my @ret = map {
            $self->obj_as_string($_)
        } @$obj;

        return "[" . join(",", @ret) . "]";
    }
    elsif ($ref eq 'HASH') {
        my %ret;
        while (my ($k, $v) = each %$obj) {
            $ret{$k} = $self->obj_as_string($v)
        }
        return "{" . join (",", map { $self->encoder->encode($_) . ":" . $ret{$_} } keys %ret) . "}";
    }
    else {
        return $self->encoder->encode($obj)
    }
}

sub as_string
{
    my $self = shift;
    my $ret = "";

    for my $s (@{$self->{statements}}) {
        # If {call} is present, then this is a function call
        if (my $f = $s->{call}) {
            my $delimiter =
                defined($s->{delimiter}) ? $s->{delimiter} : ($s->{end_of_call_chain} ? ";" : ".");
            my $args = $s->{args};
            $ret .= ($s->{object} ? "$s->{object}." : "" ) .
                "$f(" .
                    join(",",
                         map {
                             $self->obj_as_string( $_ );
                         } @$args
                     ) . ")" . $delimiter . "\n"
        }
        elsif (my $c = $s->{code}) {
            my $delimiter = defined $s->{delimiter}  ? $s->{delimiter} : ";";
            $c .= $delimiter unless $c =~ /$delimiter\s*$/s;
            $ret .= $c ."\n";
        }
    }
    return $ret;
}

sub var
{
    my ($self, $var, $value) = @_;

    my $obj = R::Writer::Var->new($var, $value, $self);
    $self->append($obj->as_string());
    return $self;
}

sub save
{
    my ($self, $file) = @_;

    open(my $fh, '>', $file) or die "Failed to open $file for writing: $!";
    print $fh, $self->as_string;
    close($fh);
}

1;

__END__

=head1 NAME 

R::Writer - Generate R Scripts From Perl

=head1 SYNOPSIS

  use R::Writer;

  {
    # x <- 1;
    # y <- x + 1;
    # cat(y);

    my $R = R();
    $R->var(x => 1)
      ->var(y => 'x + 1')
      ->call(cat => \'y')
    ;

    print $R->as_string;
    # or save to a file
    $R->save('file');
  }

=head1 DISCLAIMER

** THIS SOFTWARE IS IN ALPHA ** Patches, comments, and contributions are
very much welcome. I'm not really a statistics guy. I just happen to write
Perl code to do it.

I'm sure there are bunch of bugs lurking, but I'd like this module to be
useful, so please let me know if there are problems or missing features.

=head1 DESCRIPTION

R::Writer is a tool to generate R scripts for the "R" Statistical Computing
Tool from within Perl.

Implementation details heavily borrow from JavaScript::Writer. Without it,
this module wouldn't have been possible (I'm not insan... smart enough to
fiddle with DB package on my own. gugod++)

=head1 TODO

=over 4

=item Remove JavaScript-ness

JSON and what not are probably not needed.

=item Add Proper Documentation

=item Document Way To Feed The Script To "R"

=back

=head1 AUTHOR

Copyright (c) 2008 Daisuke Maki C<< <daisuke@endeworks.jp> >>

Much of the code is gratuitously taken from JavaScript::Writer,
which is by Kang-min Liu C<< <gugod@gugod.org> >>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut