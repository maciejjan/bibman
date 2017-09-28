package Bibliography;

use strict;
use warnings;
use feature 'unicode_strings';
use Text::BibTeX;

my $fields = {
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
    entries => []
  };
  bless $self, $class;
}

sub read {
  my $self = shift;
  my $filename = shift;
  my $bibfile = Text::BibTeX::File->new($filename, { BINMODE => 'utf-8' });
  while (my $entry = Text::BibTeX::Entry->new($bibfile)) {
    push @{$self->{entries}}, $entry;
  }
  $bibfile->close;
}

sub write {
  my $self = shift;
  my $filename = shift;

  open(my $fh, ">:encoding(utf-8)", $filename);
  for my $entry (@{$self->{entries}}) {
    print $fh $entry->print_s();
  }
  close $fh;
}

# TODO Test::BibTeX::Entry::write is currently not used because of unicode problems
# sub write {
#   my $self = shift;
#   my $filename = shift;
#   my $bibfile = Text::BibTeX::File->new();
#   $bibfile->open($filename, { MODE => 'w+', BINMODE => 'utf-8' });
#   for my $entry (@{$self->{entries}}) {
#     $entry->write($bibfile);
#   }
#   $bibfile->close;
# }

sub add_entry {
  my $self = shift;
  my $type = shift;

  my $entry = Text::BibTeX::Entry->new();
  $entry->set_metatype(Text::BibTeX::BTE_REGULAR);
  $entry->set_type($type);
  push @{$self->{entries}}, $entry;
  return $entry;
}

sub add_entry_at {
  my $self = shift;
  my $idx = shift;
  my $type = shift;
  my $entry = Text::BibTeX::Entry->new();
  $entry->set_metatype(Text::BibTeX::BTE_REGULAR);
  $entry->set_type($type);
  splice @{$self->{entries}}, $idx+1, 0, $entry;
  return $entry;
}

sub delete_entry {
  my $self = shift;
  my $idx = shift;
  splice @{$self->{entries}}, $idx, 1;
}

sub get_type {
  my $self = shift;
  my $idx = shift;
  return ${$self->{entries}}[$idx]->type;
}

sub has_type {
  my $type = shift;
  return defined($fields->{$type});
}

sub get_fields_for_type {
  my $type = shift;
  my @result = ("entry_type", "key");
  if (defined($type) && (defined($fields->{$type}))) {
    @result = (@result, @{$fields->{$type}});
  }
  return \@result;
}

sub get_property {
  my $entry = shift;
  my $field = shift;
  if ($field eq 'entry_type') {
    return $entry->type;
  } elsif ($field eq 'key') {
    return $entry->key;
  } else {
    return $entry->get($field);
  }
}

sub get_properties {
  my $entry = shift;

  my %properties = ();
  for my $field (@{get_fields_for_type($entry->type)}) {
    $properties{$field} = get_property($entry, $field);
  }
  return \%properties;
}

sub set_property {
  my $entry = shift;
  my $field = shift;
  my $value = shift;
  if ($field eq 'entry_type') {
    $entry->set_type($value);
  } elsif ($field eq 'key') {
    $entry->set_key($value);
  } else {
    return $entry->set($field, $value);
  }
}

sub set_properties {
  my $entry = shift;
  my $properties_ref = shift;
  my %properties = %$properties_ref;
  for my $field (@{get_fields_for_type($entry->type)}) {
    if (defined($properties{$field}) && ($properties{$field})) {
      set_property($entry, $field, $properties{$field});
    }
  }
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
