#!/usr/bin/env perl
# Run as: perl -CI place2yaml.pl < place.osm 
use Modern::Perl;
use YAML::Syck 'Dump';

my $in = join '', <>;

my @nodes = $in =~ m[<node(.*?)</node>]gs;

my %place;

for my $node (@nodes) {
    my ($lat) = $node =~ m[lat='(.*?)'];
    my ($lon) = $node =~ m[lon='(.*?)'];
    my ($name) = $node =~ m[<tag k='name' v='(.*?)'/>];

    $place{$name} = {
        lat => $lat,
        lon => $lon,
    } if $name;
}

say Dump(\%place);
