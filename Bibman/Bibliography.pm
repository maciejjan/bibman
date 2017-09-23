package Bibliography;

use strict;
use warnings;
use Text::BibTeX;

our $fields = {
  article => ["author", "journal", "month", "note", "number", "pages", "title", "volume", "year"]
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
  # TODO
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
