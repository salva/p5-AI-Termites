#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use GD;
use AI::Termites;

my $w = 1024;

sub scl {
    my $p = shift;
    @{$w * $p}[0, 1];
}

sub sscl {
    my $s = shift;
    $w * $s;
}

$| = 1;

my $species = $ARGV[0] // 'LoginquitasPostulo';

my $class = "AI::Termites::$species";
eval "require $class; 1" or die "unable to load $class: $@";

my $ters = $class->new(dim => 2, world_size => 1.0, n_wood => 5000, n_termites => 30);
$ters->iterate;

my $n = 0;

while (1) {

    my $im = GD::Image->new($w, $w);

    my $white = $im->colorAllocate(255,255,255);
    my $black = $im->colorAllocate(0, 0, 0);
    $im->interlaced('true');

    my $red = $im->colorAllocate(255, 0, 0);
    my $blue = $im->colorAllocate(0, 0, 255);
    my $green = $im->colorAllocate(0, 255, 0);

    for my $wood (@{$ters->{wood}}) {
        next if $wood->{taken};
        $im->filledEllipse(scl($wood->{pos}), 5, 5, $blue);
    }

    for my $ter (@{$ters->{termites}}) {
        my $color = (defined($ter->{wood_ix}) ? $red : $green);
        $im->filledEllipse(scl($ter->{pos}), 3, 3, $color);
    }

    open my $fh, ">output-$n.png";
    print $fh $im->png;
    close $fh;

    $n++;
    print "$n\r";
    
    $ters->iterate for 0..2;
}
