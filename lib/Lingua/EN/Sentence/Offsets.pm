use strict; use warnings;
package Lingua::EN::Sentence::Offsets;
require Exporter;

#ABSTRACT: Finds sentence boundaris, and returns their offsets.
our ($VERSION,@ISA,$EOS,$LOC,$AP,$P,$PAP,@ABBREVIATIONS);
use Carp qw/cluck/;
use feature qw/say/;


use base 'Exporter';
#@EXPORT_OK = qw/
our @EXPORT = qw/
				get_sentences 
				add_acronyms 
				get_acronyms 
				set_acronyms
				get_EOS 
				set_EOS
				offsets2sentences
				initial_offsets 
				_get_text
				adjust_offsets
			/;

$EOS="\001";
$P = q/[\.!?]/;			## PUNCTUATION
$AP = q/(?:'|"|»|\)|\]|\})?/;	## AFTER PUNCTUATION
$PAP = $P.$AP;

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

# 
# A regular expression cuts viciously the text into sentences, 
# and then a list of rules (some of them consist of a list of abbreviations)
# is applied on the marked text in order to fix end-of-sentence markings on 
# places which are not indeed end-of-sentence.
#------------------------------------------------------------------------------

=head2 get_sentences 

Takes text input and splits it into sentences.

=cut

sub get_sentences {
	my ($text)=@_;
	return [] unless defined $text;
	my $marked_text = first_sentence_breaking($text);
	my $fixed_marked_text = remove_false_end_of_sentence($marked_text);
	$fixed_marked_text = split_unsplit_stuff($fixed_marked_text);
	my @sentences = split(/$EOS/,$fixed_marked_text);
	my $cleaned_sentences = clean_sentences(\@sentences);
	return $cleaned_sentences;
}

=head2 add_acronyms 

user can add a list of acronyms/abbreviations.

=cut

sub add_acronyms {
	push @ABBREVIATIONS, @_;
}


=head2 get_acronyms

get defined list of acronyms.

=cut

sub get_acronyms {
	return @ABBREVIATIONS;
}

=head2 set_acronyms

run over the predefined acronyms list with your own list.

=cut

sub set_acronyms {
	@ABBREVIATIONS=@_;
}

#==============================================================================
#
# Private methods
#
#==============================================================================

## Please email me any suggestions for optimizing these RegExps.
sub remove_false_end_of_sentence {
	my ($marked_segment) = @_;
##	## don't do u.s.a.
##	$marked_segment=~s/(\.\w$PAP)$EOS/$1/sg; 
	$marked_segment=~s/([^-\w]\w$PAP\s)$EOS/$1/sg;
	$marked_segment=~s/([^-\w]\w$P)$EOS/$1/sg;         

	# don't plit after a white-space followed by a single letter followed
	# by a dot followed by another whitespace.
	$marked_segment=~s/(\s\w\.\s+)$EOS/$1/sg; 

	# fix: bla bla... yada yada
	$marked_segment=~s/(\.\.\. )$EOS([[:lower:]])/$1$2/sg; 
	# fix "." "?" "!"
	$marked_segment=~s/(['"]$P['"]\s+)$EOS/$1/sg;
	## fix where abbreviations exist
	foreach (@ABBREVIATIONS) { $marked_segment=~s/(\b$_$PAP\s)$EOS/$1/isg; }
	
	# don't break after quote unless its a capital letter.
	$marked_segment=~s/(["']\s*)$EOS(\s*[[:lower:]])/$1$2/sg;

	# don't break: text . . some more text.
	$marked_segment=~s/(\s\.\s)$EOS(\s*)/$1$2/sg;

	$marked_segment=~s/(\s$PAP\s)$EOS/$1/sg;
	return $marked_segment;
}

sub split_unsplit_stuff {
	my ($text) = @_;

	$text=~s/(\D\d+)($P)(\s+)/$1$2$EOS$3/sg;
	$text=~s/($PAP\s)(\s*\()/$1$EOS$2/gs;
	$text=~s/('\w$P)(\s)/$1$EOS$2/gs;


	$text=~s/(\sno\.)(\s+)(?!\d)/$1$EOS$2/gis;

##	# split where single capital letter followed by dot makes sense to break.
##	# notice these are exceptions to the general rule NOT to split on single
##	# letter.
##	# notice also that sibgle letter M is missing here, due to French 'mister'
##	# which is representes as M.
##	#
##	# the rule will not split on names begining or containing 
##	# single capital letter dot in the first or second name
##	# assuming 2 or three word name.
##	$text=~s/(\s[[:lower:]]\w+\s+[^[[:^upper:]M]\.)(?!\s+[[:upper:]]\.)/$1$EOS/sg;


	# add EOS when you see "a.m." or "p.m." followed by a capital letter.
	$text=~s/([ap]\.m\.\s+)([[:upper:]])/$1$EOS$2/gs;

	return $text;
}

# sub clean_sentences {
# 	my ($sentences) = @_;
# 		my $cleaned_sentences;
# 		foreach my $s (@$sentences) {
# 			next if not defined $s;
# 			next if $s!~m/\w+/;
# 			$s=~s/^\s*//;
# 			$s=~s/\s*$//;
# ##			$s=~s/\s+/ /g;
# 			push @$cleaned_sentences,$s;
# 		}
# 	return $cleaned_sentences;
# }

sub adjust_offsets {
	my ($text,$offsets) = @_;
	my $new_offsets = [];
	foreach (@$offsets){
		my $start  = $_->[0];
		my $end    = $_->[1];
		my $length = $end - $start;
		my $s = substr($text,$start,$length);
		next if $s !~ /\w+/;
		$s =~ /^(\s*).*?(\s*)$/;
		if(defined($1)){ $start += length($1); }
		if(defined($2)){ $end   -= length($2); }
		push @$new_offsets, [$start, $end];
	}
	return $new_offsets;
}

sub first_sentence_breaking {
	my ($text) = @_;
	$text=~s/\n\s*\n/$EOS/gs;	## double new-line means a different sentence.
	$text=~s/($PAP\s)/$1$EOS/gs;
	$text=~s/(\s\w$P)/$1$EOS/gs; # breake also when single letter comes before punc.
	return $text;
}

=head2 initial_offsets

First naive delimitation of sentences

=cut

sub initial_offsets {
	my ($text) = @_;
	my $offsets = [];
	my $end;
	my $text_end = length($text);

	my $start = 0;
	#while($text =~ /(\n\s*\n)|$PAP\s()|\s\w$P()/gs){
	while($text =~ /(\n\s*\n)|$PAP(\s+)|\s\w$P()/gs){

		## double new-line means a different sentence
		if(defined($1)){
			push @$offsets, [$start, $-[1]];
			$start = $+[1];
		}

		## punctuation+after_punct followed by space
		elsif(defined($2)){
			push @$offsets, [$start, $-[2]];
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

=head2 offsets2sentences

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

sub _get_text {
	open my $fh, '<', 't/text';
	my $text = join '', <$fh>;
	close $fh;
	return $text;
}

#==============================================================================
#
# Return TRUE
#
#==============================================================================

1;
