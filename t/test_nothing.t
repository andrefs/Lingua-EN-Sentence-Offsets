
BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use Lingua::EN::Sentence (get_sentences);
$loaded = 1;
print "ok 1\n";

my $text;
while(<DATA>) {
	$text.=$_;
}

my $sentences=get_sentences($text);

print "This is the test text input:\n\n";
print $text,"\n";
print "x" x 80, "\n\n";
print "And this is the splitting to sentences:\n";
map {print "==> ",$_,"\n";} @$sentences;
if (scalar(@$sentences)!=17) {
	print "not ok 2\n"; 
} else {
	print "ok 2\n";
}

__DATA__
Prof. kuku and Mr. kiki went to the beach. Later, they went to the Internet Cafe: Cafe.COM. And then, to sleep.

TITLE

This is some text which should be in a different sentence than the TITLE...

No. 1: First thing.
No. 2: 2nd thing.

Prof. kuku at the univ. of lili went to the zoo. In the zoo he saw a zebra.

This point: "." should stay in the same sentence.

A sentence with a question mark at the end: why?  A sentence with an exclamation mark at the end: wow! A sentence with both "!" and "?" at the end: hu?! A sentence with both "!" and "?" at the end: hu!?

This is a URL: http://www.kuku.com/~kuku.mumu.mama. This is another URL: http://www.Google.com

Some king of car, i.e. Toyota, or e.g. Mazda.
