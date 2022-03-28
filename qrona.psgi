#!/usr/bin/env perl
use 5.022;
use local::lib qw(local);
use lib './lib';
use QRona;

QRona->run_psgi;

