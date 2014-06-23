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
my $clusters = 3;

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
                         "clusters=s"     => \$clusters,
                         "truecolor"    => \$truecolor,
                         "top=i"          => \$top,
                       );

my $pi = 3.141592653589793;

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

    my @color;
    for my $ix (0..$clusters - 1) {
        my $angle = 2 * $pi * $ix / $clusters;
        my @c = map { 256 * 0.499 * (1 + cos ($angle - $_)) } 0, 2/3 * $pi, 4/3 * $pi;
        print "@c\n";
        push @color, $im->colorAllocate(map { 256 * 0.499 * (1 + 0.5 * cos ($angle - $_)) } 0, 2/3 * $pi, 4/3 * $pi);
    }

    my $txt = sprintf ("dim: %d, near: %.2f%%, termites: %d, wood: %d, wood taken: %d, iteration %d",
                       $dim,
                       100 * $ters->{near} / $world,
                       $termites, $wood, $ters->{taken},
                       $n );

    $im->string(gdSmallFont, 4, 4, $txt, $black);

    my $kdt = Math::Vector::Real::kdTree->new(map $_->{pos}, @{$ters->{wood}});
    @kmean = $kdt->k_means_start($clusters) unless @kmean;
    @kmean = $kdt->k_means_loop(@kmean);

    my @assign = $kdt->k_means_assign(@kmean);

    if ($dim == 2) {
        require Algorithm::ConvexHull;
        my @cluster = map [], @kmean;
        push @{$cluster[$assign[$_]]}, $_ for 0..$#assign;

        for my $cix (0..$#cluster) {
            my $ixs = $cluster[$cix];
            next unless @$ixs;
            my @ch = Algorithm::ConvexHull::convex_hull_2d(map $kdt->at($_), @$ixs);

            my $polygon = GD::Polygon->new;
            $polygon->addPt(scl($_)) for @ch;
            $im->openPolygon($polygon, $color[$cix]);
        }

        for my $wood (@{$ters->{wood}}) {
            if ($wood->{taken}) {
                $taken and $im->filledEllipse(scl($wood->{pos}), 8, 8, $orange);
            }
            else {
                $im->filledEllipse(scl($wood->{pos}), 5, 5, $blue);
            }
        }

        for my $ter (@{$ters->{termites}}) {
            my $color = (defined($ter->{wood_ix}) ? $red : $green);
            $im->filledEllipse(scl($ter->{pos}), 3, 3, $color);
        }

    }
    else {
        for my $ix (0..$#assign) {
            my $color = $color[$assign[$ix]];
            my $v = $kdt->at($ix);
            $im->filledEllipse(scl($v), 8, 8, $color);
        }
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
    
