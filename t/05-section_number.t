#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 1;
use Lingua::EN::Sentence qw/get_sentences/;
use Lingua::EN::Sentence::Offsets qw/get_sentences/;
use Data::Dump qw/dump/;

my $text = join '',<DATA>;
my $expected_s1 = Lingua::EN::Sentence::get_sentences($text);
my $got_s2      = Lingua::EN::Sentence::Offsets::get_sentences($text);

is_deeply($got_s2,$expected_s1,"L::EN::S::O vs L::EN::S");


__DATA__
ammonia-oxidizing activity per ammonia oxidizer cell.

2. Materials and methods
2.1. Samples of sewage activated sludge and description of
sewage treatment systems
