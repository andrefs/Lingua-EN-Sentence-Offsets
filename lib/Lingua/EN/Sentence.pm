package Lingua::EN::Sentence;

#==============================================================================
#
# Start of POD
#
#==============================================================================

=head1 NAME

Lingua::EN::Sentence - Module for splitting text into sentences.

=head1 SYNOPSIS

	use Lingua::EN::Sentence qw( get_sentences add_acronyms );

	add_acronyms('lt','gen');		## adding support for 'Lt. Gen.'
	my $sentences=get_sentences($text);	## Get the sentences.
	foreach my $sentence (@$sentences) {
		## do something with $sentence
	}


=head1 DESCRIPTION

The C<Lingua::EN::Sentence> module contains the function get_sentences, which splits text into its constituent sentences, based on a regular expression and a list of abbreviations (built in and given).

Certain well know exceptions, such as abreviations, may cause incorrect segmentations.  But some of them are already integrated into this code and are being taken care of.  Still, if you see that there are words causing the get_sentences() to fail, you can add those to the module, so it notices them.

=head1 ALGORITHM

Basically, I use a 'brute' regular expression to split the text into sentences.  (Well, nothing is yet split - I just mark the end-of-sentence).  Then I look into a set of rules which decide when an end-of-sentence is justified and when it's a mistake. In case of a mistake, the end-of-sentence mark is removed. 

What are such mistakes? Cases of abbreviations, for example. I have a list of such abbreviations (Please see `Acronym/Abbreviations list' section), and more general rules (for example, the abbreviations 'i.e.' and '.e.g.' need not to be in the list as a special rule takes care of all single letter abbreviations).

=head1 FUNCTIONS

All functions used should be requested in the 'use' clause. None is exported by default.

=item get_sentences( $text )

The get sentences function takes a scalar containing ascii text as an argument and returns a reference to an array of sentences that the text has been split into.
Returned sentences will be trimmed (beginning and end of sentence) of white-spaces.
Strings with no alpha-numeric characters in them, won't be returned as sentences.

=item add_acronyms( @acronyms )

This function is used for adding acronyms not supported by this code.  Please see `Acronym/Abbreviations list' section for the abbreviations already supported by this module.

=item get_acronyms(	)

This function will return the defined list of acronyms.

=item set_acronyms( @my_acronyms )

This function replaces the predefined acroym list with the given list.

=item get_EOS(	)

This function returns the value of the string used to mark the end of sentence. You might want to see what it is, and to make sure your text doesn't contain it. You can use set_EOS() to alter the end-of-sentence string to whatever you desire.

=item set_EOS( $new_EOS_string )

This function alters the end-of-sentence string used to mark the end of sentences. 

=head1 Acronym/Abbreviations list

Currently supported acronym lists are:

	PEOPLE ( 'jr', 'mr', 'mrs', 'ms', 'dr', 'prof', 'sr' )
	ARMY ( 'col','gen', 'lt', 'cmdr' )
	INSTITUTES ( 'dept', 'univ' )
	COMPANIES ( 'inc', 'ltd' )
	PLACES = ( 'arc', 'al', 'ave', "blv?d", 'cl', 'ct', 'cres', 'dr', "expy?",
		"fw?y", "hwa?y", 'la', "pde?", 'pl', 'plz', 'rd', 'st', 'tce',
		'Ala' , 'Ariz', 'Ark', 'Cal', 'Calif', 'Col', 'Colo', 'Conn',
		'Del', 'Fed' , 'Fla', 'Ga', 'Ida', 'Id', 'Ill', 'Ind', 'Ia',
		'Kan', 'Kans', 'Ken', 'Ky' , 'La', 'Me', 'Md', 'Is', 'Mass', 
		'Mich', 'Minn', 'Miss', 'Mo', 'Mont', 'Neb', 'Nebr' , 'Nev',
		'Mex', 'Okla', 'Ok', 'Ore', 'Oreg', 'Penna', 'Penn', 'Pa'  , 'Dak',
		'Tenn', 'Tex', 'Ut', 'Vt', 'Va', 'Wash', 'Wis', 'Wisc', 'Wy',
		'Wyo', 'USAFA', 'Alta' , 'Man', 'Ont', 'Qué', 'Sask', 'Yuk')
	MONTHS = ('jan','feb','mar','apr','may','jun','jul','aug','sep','oct','nov','dec', 'sept')
	MISC ( 'vs', 'etc', 'no' )

If I come across a good general-purpose list - I'll incorporate it into this module.
Feel free to suggest such lists. 

=head1 SEE ALSO

	Text::Sentence

=head1 AUTHOR

Shlomo Yona E<lt>Shlomo.Yona@Siftology.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2001 Siftology Inc.. All rights reserved.

This library is free software. 
You can redistribute it and/or modify it under the same terms as Perl itself.  

=cut

#==============================================================================
#
# End of POD
#
#==============================================================================


#==============================================================================
#
# Pragmas
#
#==============================================================================
require 5.005_03;
use strict;

#==============================================================================
#
# Modules
#
#==============================================================================
require Exporter;

#==============================================================================
#
# Public globals
#
#==============================================================================
use vars qw/$VERSION @ISA @EXPORT_OK $EOS $AP $P $PAP @ABBREVIATIONS/;
use Carp qw/cluck/;

$VERSION = '0.16';
@ISA = qw( Exporter );
@EXPORT_OK = qw( get_sentences 
		add_acronyms get_acronyms set_acronyms
		get_EOS set_EOS);

$EOS="\001";
$P = q/[\.!?]/;			## PUNCTUATION
$AP = q/(?:'|"|»|\)|\]|\})?\s/;	## AFTER PUNCTUATION
$PAP = $P.$AP;

my @PEOPLE = ( 'jr', 'mr', 'mrs', 'ms', 'dr', 'prof', 'sr' );
my @ARMY = ( 'col','gen', 'lt', 'cmdr' );
my @INSTITUTES = ( 'dept', 'univ' );
my @COMPANIES = ( 'inc', 'ltd' );
my @PLACES = ( 'arc', 'al', 'ave', "blv?d", 'cl', 'ct', 'cres', 'dr', "expy?",
		"fw?y", "hwa?y", 'la', "pde?", 'pl', 'plz', 'rd', 'st', 'tce',
		'Ala' , 'Ariz', 'Ark', 'Cal', 'Calif', 'Col', 'Colo', 'Conn',
		'Del', 'Fed' , 'Fla', 'Ga', 'Ida', 'Id', 'Ill', 'Ind', 'Ia',
		'Kan', 'Kans', 'Ken', 'Ky' , 'La', 'Me', 'Md', 'Is', 'Mass', 
		'Mich', 'Minn', 'Miss', 'Mo', 'Mont', 'Neb', 'Nebr' , 'Nev',
		'Mex', 'Okla', 'Ok', 'Ore', 'Penna', 'Penn', 'Pa'  , 'Dak',
		'Tenn', 'Tex', 'Ut', 'Vt', 'Va', 'Wash', 'Wis', 'Wisc', 'Wy',
		'Wyo', 'USAFA', 'Alta' , 'Man', 'Ont', 'Qué', 'Sask', 'Yuk');
my @MONTHS = ('jan','feb','mar','apr','may','jun','jul','aug','sep','oct','nov','dec','sept');
my @MISC = ( 'vs', 'etc', 'no' );

@ABBREVIATIONS = (@PEOPLE, @ARMY, @INSTITUTES, @COMPANIES, @PLACES, @MONTHS, @MISC ); 


#==============================================================================
#
# Public methods
#
#==============================================================================

#------------------------------------------------------------------------------
# get_sentences - takes text input and splits it into sentences.
# A regular expression cuts viciously the text into sentences, 
# and then a list of rules (some of them consist of a list of abbreviations)
# is applied on the marked text in order to fix end-of-sentence markings on 
# places which are not indeed end-of-sentence.
#------------------------------------------------------------------------------
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

#------------------------------------------------------------------------------
# add_acronyms - user can add a list of acronyms/abbreviations.
#------------------------------------------------------------------------------
sub add_acronyms {
	push @ABBREVIATIONS, @_;
}

#------------------------------------------------------------------------------
# get_acronyms - get defined list of acronyms.
#------------------------------------------------------------------------------
sub get_acronyms {
	return @ABBREVIATIONS;
}

#------------------------------------------------------------------------------
# set_acronyms - run over the predefined acronyms list with your own list.
#------------------------------------------------------------------------------
sub set_acronyms {
	@ABBREVIATIONS=@_;
}

#------------------------------------------------------------------------------
# get_EOS - get the value of the $EOS (end-of-sentence mark).
#------------------------------------------------------------------------------
sub get_EOS {
	return $EOS;
}

#------------------------------------------------------------------------------
# set_EOS - set the value of the $EOS (end-of-sentence mark).
#------------------------------------------------------------------------------
sub set_EOS {
	my ($new_EOS) = @_;
	if (not defined $new_EOS) {
		cluck "Won't set \$EOS to undefined value!\n";
		return $EOS;
	}
	return $EOS = $new_EOS;
}


#==============================================================================
#
# Private methods
#
#==============================================================================

## Please email me any suggestions for optimizing these RegExps.
sub remove_false_end_of_sentence {
	my ($marked_segment) = @_;
##	## if one letter before dot - not EOS
##	$marked_segment=~s/(\s\w$PAP)$EOS/$1/sg; 
##	## don't do u.s.a.
##	$marked_segment=~s/(\.\w$PAP)$EOS/$1/sg; 
	$marked_segment=~s/(\W\w$PAP)$EOS/$1/sg;
	$marked_segment=~s/(\W\w$P)$EOS/$1/sg;         

	# don't split |John P. Stenbit| into |John P.| and |Stenbit|
	$marked_segment=~s/([A-Z]\w+\s+\S$P\s*)$EOS(\s*[A-Z])/$1$2/sg; 

	# fix: bla bla... yada yada
	$marked_segment=~s/(\.\.\. )$EOS([a-z])/$1$2/sg; 
	# fix "." "?" "!"
	$marked_segment=~s/(['"]$P['"]\s+)$EOS/$1/sg;
	## fix where abbreviations exist
	map {$marked_segment=~s/(\b$_$PAP)$EOS/$1/isg;} @ABBREVIATIONS;
	
	# fix where M. in end of sentence. This is French version to Mr.
	$marked_segment=~s/(M\.\s+)$EOS(\s*[A-Z])/$1$2/sg;
	$marked_segment=~s/(M\.\s*)$EOS(\s+[A-Z])/$1$2/sg;

	# don't break after quote unless its a capital letter.
	$marked_segment=~s/(["']\s*)$EOS(\s+[^A-Z])/$1$2/sg;
	$marked_segment=~s/(["']\s+)$EOS(\s*[^A-Z])/$1$2/sg;

	$marked_segment=~s/(\s$PAP)$EOS/$1/sg;
	return $marked_segment;
}

sub split_unsplit_stuff {
	my ($text) = @_;
	# don't split |John P. Stenbit| into |John P.| and |Stenbit|
	$text=~s/([A-Z]\w+\s+\S$P\s*)$EOS(\s*[A-Z])/$1$2/sg;
	$text=~s/(\D\d+)($P)(\s+)/$1$2$EOS$3/sg;
	return $text;
}

sub clean_sentences {
	my ($sentences) = @_;
		my $cleaned_sentences;
		foreach my $s (@$sentences) {
			next if not defined $s;
			next if $s!~m/\w+/;
			$s=~s/^\s*//;
			$s=~s/\s*$//;
##			$s=~s/\s+/ /g;
			push @$cleaned_sentences,$s;
		}
	return $cleaned_sentences;
}

sub first_sentence_breaking {
	my ($text) = @_;
	$text=~s/\n\s*\n/$EOS/gs;	## double new-line means a different sentence.
	$text=~s/($PAP)/$1$EOS/gs;
	$text=~s/(\s\w$P)/$1$EOS/gs; # breake also when single letter comes before punc.
	return $text;
}

#==============================================================================
#
# Return TRUE
#
#==============================================================================

1;
