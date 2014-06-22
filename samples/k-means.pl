#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use GD;
use AI::Termites;
use Math::Vector::Real::kdTree;

use Getopt::Long;

my $world = 1;
my $specie = 'NemusNidor';
my $termites = 20;
my $wood = 200;
my $near;
my $one_of = 5;
my $width = 1024;
my $dim = 2;
my $taken = 0;
my $output = "output";
my $truecolor = 0;
my $top = 0;
my $kmeans = 3;

my $result = GetOptions( "world-size=s" => \$world,
                         "specie=s"     => \$specie,
                         "termites=i"   => \$termites,
                         "wood=i"       => \$wood,
                         "near=s"       => \$near,
                         "one-of=i"     => \$one_of,
                         "width=i"      => \$width,
                         "dim=i"        => \$dim,
                         "taken"        => \$taken,
                         "output=s"     => \$output,
                         "kmeans=s"     => \$kmeans,
                         "truecolor"    => \$truecolor,
                         "top=i"          => \$top,
                       );

sub scl {
    my $p = shift;
    @{$width * $p}[0, 1];
}

sub sscl {
    my $s = shift;
    $width * $s;
}

$| = 1;

my $class = "AI::Termites::$specie";
eval "require $class; 1" or die "unable to load $class: $@";

my $ters = $class->new(dim => $dim, world_size => $world,
                       n_wood => $wood, n_termites => $termites,
                       near => $near);

my $n = 0;
my $fn = 0;

my @kmean;

while (1) {

    my $im = GD::Image->new($width, $width, $truecolor);

    my $white = $im->colorAllocate(255,255,255);
    $im->filledRectangle(0, 0, $width, $width, $white);

    my $black = $im->colorAllocate(0, 0, 0);
    # $im->interlaced('true');

    my $red = $im->colorAllocate(255, 0, 0);
    my $blue = $im->colorAllocate(0, 0, 255);
    my $orange = $im->colorAllocate(255, 128, 0);
    my $green = $im->colorAllocate(0, 255, 0);

    my @color = ($red, $blue, $orange, $green);

    my $txt = sprintf ("dim: %d, near: %.2f%%, termites: %d, wood: %d, wood taken: %d, iteration %d",
                       $dim,
                       100 * $ters->{near} / $world,
                       $termites, $wood, $ters->{taken},
                       $n );

    $im->string(gdSmallFont, 4, 4, $txt, $black);

    my $kdt = Math::Vector::Real::kdTree->new(map $_->{pos}, @{$ters->{wood}});
    @kmean = $kdt->k_means_start($kmeans) unless @kmean;
    @kmean = $kdt->k_means_loop(@kmean);
    my $sum = Math::Vector::Real::V(0,0);
    $sum += $_->{pos} for @{$ters->{wood}};
    print "k-means: @kmean\n";
    print "sum: $kdt->{tree}[3]\n";
    print "sum: $sum\n";

    my @assign = $kdt->k_means_assign(@kmean);
    for my $ix (0..$#assign) {
        my $color = $color[$assign[$ix]];
        my $v = $kdt->at($ix);
        $im->filledEllipse(scl($v), 8, 8, $color);
    }

    for my $k (0..$#kmean) {
        my $color = $color[$k];
        $im->filledEllipse(scl($kmean[$k]), 10, 10, $black);
        $im->filledEllipse(scl($kmean[$k]), 8, 8, $color);
    }

    my $name = sprintf "%s-%05d.png", $output, $fn;
    open my $fh, ">", $name;
    print $fh $im->png;
    close $fh;

    print "$n ($fn)\r";
    for (1..$one_of) {
        $n++;
        $ters->iterate;
    }
    $fn++;
    last if ($top and $n > $top);
}

