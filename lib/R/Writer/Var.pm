# $Id: /mirror/coderepos/lang/perl/R-Writer/trunk/lib/R/Writer/Var.pm 42804 2008-02-25T10:17:18.239702Z daisuke  $

package R::Writer::Var;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors($_) for qw(name value writer);

sub new
{
    my $class = shift;
    my $self  = $class->SUPER::new({ name => $_[0], value => $_[1], writer => $_[2] || R::Writer::R() });
    return $self;
}

sub as_string
{
    my $self  = shift;
    my $var   = $self->name;
    my $value = $self->value;

    my $s = "";

    my $ref = defined $value ? ref $value : undef;
    if (!defined $value) {
        $s = "$var;";
    }
    elsif (! $ref) {
        $s = "$var <- $value;";
    } 
    elsif ($ref eq 'ARRAY' || $ref eq 'HASH') {
        $s = "$var <- " . $self->encoder->encode($value) . ";"
    }
    elsif ($ref eq 'CODE') {
        $s = "$var <- " . $self->function($value);
    }
    elsif ($ref =~ /^R::Writer/) {
        $s = "$var <- " . $value->as_string();
    }
    elsif ($ref eq 'REF') {
        my $j = $self->new;
        $j->var($var => $$value);
        $s = $j->as_string;
    }
    elsif ($ref eq 'SCALAR') {
        if (defined $$value) {
            my $v = $self->obj_as_string($value);

            $s = "var $var = $v;";
        }
        else {
            $s = "var $var;";
        }

        eval {
            R::Writer::Var->new(
                $value,
                {
                    name => $var,
                    jsw  => $self
                }
            );
        };
    }

    return $s;
}

1;
