#!/usr/bin/env perl
# Run as: perl -CI place2yaml.pl < place.osm > place.yml
use Modern::Perl;
use YAML::Syck 'Dump';

my $in = join '', <>;

my @nodes = $in =~ m[<node(.*?)</node>]gs;

my %place;

for my $node (@nodes) {
    my ($lat) = $node =~ m[lat='(.*?)'];
    my ($lon) = $node =~ m[lon='(.*?)'];
    my ($name) = $node =~ m[<tag k='name' v='(.*?)'/>];

    $place{$name} = [
        $lat,
        $lon,
    ] if $name;
}

say Dump(\%place);
