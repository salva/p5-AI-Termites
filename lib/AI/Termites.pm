package AI::Termites;

use 5.010;

our $VERSION = '0.01';

use strict;
use warnings;

use Math::Vector::Real;
use Math::Vector::Real::Random;

use List::Util;
use Carp;

sub new {
    my ($class, %opts) = @_;
    my ($dim, $box);
    $box = delete $opts{box};
    if (defined $box) {
	$box = V(@$box);
	$dim = @$box;
    }
    else {
	$dim = delete $opts{dim} // 3;
	my $size = delete $opts{world_size} // 1000;
	$box = Math::Vector::Real->cube($dim, $size);
    }
    my $n_termines = delete $opts{n_termites} // 50;
    my $n_wood = delete $opts{n_wood} // 200;
    my $iterations = delete $opts{iterations} // 0;
    my $termite_speed = delete $opts{termite_speed} // abs($box)/10;
    my $near = delete $opts{near} // abs($box)/50;
    %opts and croak "unknown parameter(s) ". join(", ", keys %opts);

    my @wood;
    my @termites;

    my $self = { wood => \@wood,
		 termites => \@termites,
		 iteration => 0,
		 speed => $termite_speed,
		 box => $box,
                 near => $near,
                 inear2 => 1/($near * $near),
		 dim => $dim };

    bless $self, $class;

    push @wood, $self->new_wood for (1..$n_wood);
    push @termites, $self->new_termite for (1..$n_wood);
    $self->iterate for (1..$iterations);
    $self;
}

sub dim { shift->{dim} }

sub box { shift->{box} }

sub new_wood {
    my $self = shift;
    my $wood = { pos => $self->{box}->random_in_box,
		 taken => 0 };
}

sub new_termite {
    my $self = shift;
    my $termite = { pos => $self->{box}->random_in_box };
}

sub iterate {
    my $self = shift;

    $self->before_termites_move;

    for my $term (@{$self->{termites}}) {
	$self->termite_move($term);
    }
    $self->before_termites_action;
    for my $term (@{$self->{termites}}) {
	$self->termite_action($term);
    }
    $self->after_termites_action;
}

sub termite_move {
    my ($self, $termite) = @_;
    $termite->{pos} = $self->{box}->wrap( $termite->{pos} +
					  Math::Vector::Real->random_normal($self->{dim},
									    $self->{speed}));
}

sub before_termites_move {}
sub before_termites_action {}
sub after_termites_action {}

sub termite_action {
    my ($self, $termite) = @_;
    if (defined $termite->{wood_ix}) {
        if ($self->termite_leave_wood_p($termite)) {
            $self->termite_leave_wood($termite);
        }
    }
    else {
        my $wood_ix = $self->termite_take_wood_p($termite);
        defined $wood_ix and $self->termite_take_wood($termite, $wood_ix);
    }
}

sub termite_take_wood {
    my ($self, $termite, $wood_ix) = @_;
    $termite->{wood_ix} and croak "termite is already carrying some wood";
    $termite->{wood_ix} = $wood_ix;
    $self->{wood}[$wood_ix]{taken} = 1;
}

sub termite_leave_wood {
    my ($self, $termite) = @_;
    my $wood_ix = delete $termite->{wood_ix} //
	croak "termite can not leave wood because it is carrying nothing";
    $self->{wood}[$wood_ix]{taken} = 0;
    $self->{wood}[$wood_ix]{pos}->set($termite->{pos});
}


1;
__END__

=head1 NAME

AI::Termites - Perl extension for blah blah blah

=head1 SYNOPSIS

  use AI::Termites;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for AI::Termites, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Salvador Fandino, E<lt>salva@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Salvador Fandino

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
