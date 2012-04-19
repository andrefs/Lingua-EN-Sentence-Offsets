use strict; use warnings;
package Lingua::EN::Sentence::Offsets;
require Exporter;

#ABSTRACT: Finds sentence boundaris, and returns their offsets.


my ($EOS,$AP,$P,$PAP,@ABBREVIATIONS);
use Carp qw/cluck/;
use feature qw/say/;
use utf8::all;

use base 'Exporter';
#@EXPORT_OK = qw/
our @EXPORT = qw/
				get_sentences 
				get_offsets
				add_acronyms 
				get_acronyms 
				set_acronyms
			/;


$EOS="\001";$P = q/[\.!?]/;$AP = q/(?:'|"|»|\)|\]|\})?/;$PAP = $P.$AP;

my @PEOPLE = ( 'jr', 'mr', 'mrs', 'ms', 'dr', 'prof', 'sr', "sens?", "reps?", 'gov',
		"attys?", 'supt',  'det', 'rev' );


my @ARMY = ( 'col','gen', 'lt', 'cmdr', 'adm', 'capt', 'sgt', 'cpl', 'maj' );
my @INSTITUTES = ( 'dept', 'univ', 'assn', 'bros' );
my @COMPANIES = ( 'inc', 'ltd', 'co', 'corp' );
my @PLACES = ( 'arc', 'al', 'ave', "blv?d", 'cl', 'ct', 'cres', 'dr', "expy?",
		'dist', 'mt', 'ft',
		"fw?y", "hwa?y", 'la', "pde?", 'pl', 'plz', 'rd', 'st', 'tce',
		'Ala' , 'Ariz', 'Ark', 'Cal', 'Calif', 'Col', 'Colo', 'Conn',
		'Del', 'Fed' , 'Fla', 'Ga', 'Ida', 'Id', 'Ill', 'Ind', 'Ia',
		'Kan', 'Kans', 'Ken', 'Ky' , 'La', 'Me', 'Md', 'Is', 'Mass', 
		'Mich', 'Minn', 'Miss', 'Mo', 'Mont', 'Neb', 'Nebr' , 'Nev',
		'Mex', 'Okla', 'Ok', 'Ore', 'Penna', 'Penn', 'Pa'  , 'Dak',
		'Tenn', 'Tex', 'Ut', 'Vt', 'Va', 'Wash', 'Wis', 'Wisc', 'Wy',
		'Wyo', 'USAFA', 'Alta' , 'Man', 'Ont', 'Qué', 'Sask', 'Yuk');
my @MONTHS = ('jan','feb','mar','apr','may','jun','jul','aug','sep','oct','nov','dec','sept');
my @MISC = ( 'vs', 'etc', 'no', 'esp' );

@ABBREVIATIONS = (@PEOPLE, @ARMY, @INSTITUTES, @COMPANIES, @PLACES, @MONTHS, @MISC ); 

=method get_offsets

Takes text input and returns reference to array containin pairs of character
offsets, corresponding to the sentences start and end positions.

=cut

sub get_offsets {
	my ($text) = @_;
	return [] unless defined $text;
	my $offsets = initial_offsets($text);
	remove_false_eos($text,$offsets);
	split_unsplit_stuff($text,$offsets);
	adjust_offsets($text,$offsets);
	return $offsets;
}


=method get_sentences 

Takes text input and splits it into sentences.

=cut

sub get_sentences {
	my ($text) = @_;
	my $offsets = get_offsets($text);
	my $sentences = offsets2sentences($text,$offsets);
	return $sentences;
}

=method add_acronyms 

user can add a list of acronyms/abbreviations.

=cut

sub add_acronyms {
	push @ABBREVIATIONS, @_;
}


=method get_acronyms

get defined list of acronyms.

=cut

sub get_acronyms {
	return @ABBREVIATIONS;
}

=method set_acronyms

run over the predefined acronyms list with your own list.

=cut

sub set_acronyms {
	@ABBREVIATIONS=@_;
}

=method remove_false_eos

=cut

sub remove_false_eos {
	my ($text,$offsets) = @_;
	my $size = @$offsets;
	for(my $i=0; $i<$size-1; $i++){
		my $start  = $offsets->[$i][0];
		my $end    = $offsets->[$i][1];
		my $length = $end-$start;
		my $s = substr($text,$start,$length);
		my $j=$i+1;

		my $unsplit = 0;
		$unsplit = 1 if $s =~ /[^-\w]\w$PAP\s$/s;
		$unsplit = 1 if $s =~ /[^-\w]\w$P$/s;

		# don't split after a white-space followed by a single letter followed
		# by a dot followed by another whitespace.
		$unsplit = 1 if $s =~ /\s\w\.\s+$/;

		# fix: bla bla... yada yada
		my $t = substr($text,$offsets->[$j][0], $offsets->[$j][1]-$offsets->[$j][0]);
		$unsplit = 1 if $s =~ /\.\.\.\s*$/s and $t =~ /^\s*[[:lower:]]/s;

		# fix "." "?" "!"
		$unsplit = 1 if $s =~ m{['"]$P['"]\s+$}s;

		## fix where abbreviations exist
		foreach (@ABBREVIATIONS){ $unsplit = $1 if $s =~ /\b$_$PAP\s$/is; }

		# don't break after quote unless its a capital letter.
		$unsplit = 1 if $s =~ /["']\s*$/s and $t =~ /^\s*[[:lower:]]/s;

		# don't break: text . . some more text.
		$unsplit = 1 if $s =~ /\s\.\s$/s and $t =~ /^\s*/s;

		$unsplit = 1 if $s =~ /\s$PAP\s$/s;

		_merge_forward($offsets,$i) if $unsplit;
	}
	for(my $i=0; $i<$size; $i++){ splice @$offsets, $i,1 unless defined($offsets->[$i]); }
}

sub _merge_forward {
	my ($offsets,$i) = @_;
	my $j = $i+1;
	return $offsets unless defined($offsets->[$j]);

	$offsets->[$j][0] = $offsets->[$i][0];
	delete $offsets->[$i];

	#splice @$offsets, $i, 1;
}

=method split_unsplit_stuff

Finds additional split points in the middle of previously defined sentences.

=cut

sub split_unsplit_stuff {
	my ($text,$offsets) = @_;
	my $size = @$offsets;
	for(my $i=0; $i<$size-1; $i++){
		my $start  = $offsets->[$i][0];
		my $end    = $offsets->[$i][1];
		my $length = $end-$start;
		my $s = substr($text,$start,$length);

		my $split_points = [];
		while($s =~ /(\D\d+$P)(\s+)/g){
			$end   = $+[1];
			$start = $-[2];
			push @$split_points,[$end,$start];
		}
		while($s =~ /($PAP\s)(\s*\()/g){
			$end   = $+[1];
			$start = $-[2];
			push @$split_points,[$end,$start];
		}
		while($s =~ /('\w$P)(\s)/g){
			$end   = $+[1];
			$start = $-[2];
			push @$split_points,[$end,$start];
		}
		while($s =~ /(\sno\.)(\s+)(?!\d)/g){
			$end   = $+[1];
			$start = $-[2];
			push @$split_points,[$end,$start];
		}

		foreach( sort { $a->[0] <=> $b->[0] } @$split_points){
			_split_sentence($offsets,$i,$_->[0],$_->[1]);
		}
	}
}



sub _split_sentence {
	my ($offsets,$i,$end1,$start2) = @_;
	my $end2 = $offsets->[$i][1];
	$offsets->[$i][1] = $end1;
	$start2 //= $end1;
	push $offsets, [$start2, $end2];
}

=method adjust_offsets 

Minor adjusts to offsets (leading/trailing whitespace, etc)

=cut

sub adjust_offsets {
	my ($text,$offsets) = @_;
	my $new_offsets = [];
	my $size = @$offsets;
	for(my $i=0; $i<$size; $i++){
		my $start  = $offsets->[$i][0];
		my $end    = $offsets->[$i][1];
		my $length = $end - $start;
		my $s = substr($text,$start,$length);
		if ($s !~ /\w+/){
			delete $offsets->[$i];
			next;
		}
		$s =~ /^(\s*).*?(\s*)$/;
		if(defined($1)){ $start += length($1); }
		if(defined($2)){ $end   -= length($2); }
		$offsets->[$i] = [$start, $end];
	}
	for(my $i=0; $i<$size; $i++){ splice @$offsets, $i,1 unless defined($offsets->[$i]); }
}

=method initial_offsets

First naive delimitation of sentences

=cut

sub initial_offsets {
	my ($text) = @_;
	my $offsets = [];
	my $end;
	my $text_end = length($text);

	my $start = 0;
	#while($text =~ /(\n\s*\n)|$PAP\s()|\s\w$P()/gs){
	while($text =~ /(\n\s*\n)|$PAP(\s)|\s\w$P()/gs){

		## double new-line means a different sentence
		if(defined($1)){
			push @$offsets, [$start, $-[1]];
			$start = $+[1];
		}

		## punctuation+after_punct followed by space
		elsif(defined($2)){
			push @$offsets, [$start, $+[2]];
			$start = $+[2];
		}

		## break also when single letter comes before punc.
		elsif(defined($3)){
			push @$offsets, [$start, $-[3]];
			$start = $+[3];
		}
	}

	push @$offsets, [ $start, $text_end ]
		unless substr($text,$start,$text_end-$start) =~ /^\s*$/;

	return $offsets;
}

=method offsets2sentences

Given a list of sentence boundaries offsets and a text, returns an array with the text split into sentences.

=cut

sub offsets2sentences {
	my ($text, $offsets) = @_;
	my $sentences = [];
	foreach my $o ( sort {$a->[0] <=> $b->[0]} @$offsets) {
		my $start = $o->[0];
		my $length = $o->[1]-$o->[0];
		push @$sentences, substr($text,$start,$length);
	}
	return $sentences;
}

1;

__END__

=head1 SYNOPSIS

	use Lingua::EN::Sentence::Offsets qw(get_offsets get_sentences);
	 
	my $offsets = get_offsets($text);     ## Get the offsets.
	foreach my $o (@$offsets) {
		my $start  = $o->[0];
		my $length = $o->[1]-$o->[0];

		my $sentence = substr($text,$start,$length)  ## Get a sentence.
		# ...
	}

	### or

	my $sentences = get_sentences($text);     
	foreach my $sentence (@$sentences) {
		## do something with $sentence
	}

=head1 ACKNOWLEDGEMENTS

Based on the original module L<Lingua::EN::Sentence>, from Shlomo Yona (SHLOMOY)

=head1 SEE ALSO

L<Lingua::EN::Sentence>, L<Text::Sentence>
