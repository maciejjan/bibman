package Bibliography;

use strict;
use warnings;
use feature 'unicode_strings';
use Text::BibTeX;

our $fields = {
  article => ["author", "journal", "month", "note", "number", "pages", "title", "volume", "year"],
  book => ["address", "author", "edition", "editor", "month", "note", "number", "publisher", "series", "title", "volume", "year"],
  booklet => ["address", "author", "howpublished", "month", "note", "title", "year"],
  inbook => ["address", "author", "chapter", "edition", "editor", "month", "note", "number", "pages", "publisher", "series", "title", "type", "volume", "year"],
  incollection => [],
  inproceedings => ["address", "author", "booktitle", "chapter", "edition", "editor", "month", "note", "number", "pages", "publisher", "series", "title", "type", "volume", "year"],
  manual => [],
  thesis => ["address", "author", "month", "note", "school", "title", "type", "year"],
  phdthesis => ["address", "author", "month", "note", "school", "title", "type", "year"],
  misc => [],
  proceedings => [],
  techreport => [],
  unupublished => [],
};

sub new {
  my $class = shift;
  my $self = {
    entries => [],
    entries_by_key => {}
  };
  bless $self, $class;
}

sub read {
  my $self = shift;
  my $filename = shift;
  my $bibfile = Text::BibTeX::File->new($filename, { BINMODE => 'utf-8' });
  while (my $entry = Text::BibTeX::Entry->new($bibfile)) {
    push @{$self->{entries}}, $entry;
    $self->{entries_by_key}->{$entry->key} = $entry;
  }
}

sub write {
  my $self = shift;
  my $filename = shift;
  my $bibfile = Text::BibTeX::File->new($filename, "w+", { BINMODE => 'utf-8' });
  for my $entry (@{$self->{entries}}) {
    $entry->write($bibfile);
  }
}

sub add_entry {
  my $self = shift;
  my $type = shift;
  my $key = shift;

  my $entry = Text::BibTeX::Entry->new(make_bibtex($type, $key, {}));
  push @{$self->{entries}}, $entry;
  $self->{entries_by_key}->{$key} = $entry;
}

sub get_type {
  my $self = shift;
  my $key = shift;
  return $self->{entries_by_key}->{$key}->type;
}

sub get_properties {
  my $self = shift;
  my $key = shift;

  my $entry = $self->{entries_by_key}->{$key};
  my %properties = ();
  for my $field (@{$fields->{$entry->type}}) {
    $properties{$field} = $entry->get($field);
  }
  return \%properties;
}

sub make_bibtex {
  my $type = shift;
  my $key = shift;
  my $properties_ref = shift;
  my %properties = %$properties_ref;

  my $result = "@" . $type . "{$key";
  for my $key (sort keys %properties) {
    if (defined($properties{$key})) {
      $result .= ",\n  $key = {$properties{$key}}";
    }
  }
  $result .= "\n}";
  return $result;
}

sub format_authors {
	my $entry = shift;
	my @authors = $entry->names('author');
	if ($#authors > 1) {
		return $authors[0]->part('last') . " et al.";
	} elsif ($#authors == 1) {
		return $authors[0]->part('last') . " and " .
		       $authors[1]->part('last');
	} elsif ($#authors == 0) {
		return $authors[0]->part('last');
	} else {
		return "unknown";
	}
}

1;
