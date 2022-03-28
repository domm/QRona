#!/usr/bin/env perl
use 5.034;
use CheckCovidCert;
use Data::Dumper;

my $c3 = CheckCovidCert->new(
    cert => $ARGV[0]
);
say Dumper $c3->decode;


