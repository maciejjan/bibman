# This file is part of Bibman -- a console tool for managing BibTeX files.
# Copyright 2017, Maciej Sumalvico <macjan@o2.pl>

# Bibman is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Bibman is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Bibman. If not, see <http://www.gnu.org/licenses/>.

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
  incollection => ["address", "author", "booktitle", "chapter", "edition", "editor", "month", "note", "number", "pages", "publisher", "series", "title", "type", "volume", "year"],
  inproceedings => ["address", "author", "booktitle", "chapter", "edition", "editor", "month", "note", "number", "pages", "publisher", "series", "title", "type", "volume", "year"],
  manual => ["address", "author", "edition", "month", "note", "organization", "title", "year"],
  thesis => ["address", "author", "month", "note", "school", "title", "type", "year"],
  phdthesis => ["address", "author", "month", "note", "school", "title", "type", "year"],
  misc => ["author", "howpublished", "month", "note", "school", "title", "type", "year"],
  proceedings => ["address", "editor", "month", "note", "number", "organization", "publisher", "series", "title", "volume", "year"],
  techreport => ["address", "author", "institution", "month", "note", "number", "title", "type", "year"],
  unpublished => ["author", "month", "note", "title", "year"]
};

sub new {
  my $class = shift;
  my $filename = shift;
  my $self = {
    filename => undef,
    entries => []
  };
  bless $self, $class;
  if (defined($filename)) {
    $self->read($filename);
  }
  return $self;
}

sub get {
  my $self = shift;
  my $idx = shift;
  return ${$self->{entries}}[$idx];
}

sub read {
  my $self = shift;
  my $filename = shift;
  $self->{filename} = $filename;
  $self->{entries} = [];
  my $bibfile = Text::BibTeX::File->new($filename, { BINMODE => 'utf-8' });
  while (my $entry = Text::BibTeX::Entry->new($bibfile)) {
    push @{$self->{entries}}, $entry;
  }
  $bibfile->close;
}

# TODO change: filename implicit!
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
#   my $type = shift;
#   my $entry = Text::BibTeX::Entry->new();
  my $entry = shift;
#   $entry->set_metatype(Text::BibTeX::BTE_REGULAR);
#   $entry->set_type($type);
  splice @{$self->{entries}}, $idx, 0, $entry;
#   return $entry;
}

sub delete_entry {
  my $self = shift;
  my $idx = shift;
  splice @{$self->{entries}}, $idx, 1;
}

sub replace_entry_at {
  my $self = shift;
  my $idx = shift;
  my $entry = shift;
  ${$self->{entries}}[$idx] = $entry;
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
