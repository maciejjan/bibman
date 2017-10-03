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

package TrieAutocompleter;

use strict;
use warnings;
use feature 'unicode_strings';
use Tree::Trie;
use Bibman::Autocompleter;

@ISA = (Autocompleter);


sub new {
  my $class = shift;
#   my $self = {
#     trie => new Tree:Trie,
#     query => undef,
#     suggestions => undef,
#     idx => undef
#   };
  my $self = Autocompleter::new(@_);
  $self->{trie} = new Tree:Trie;
  bless $self, $class;
}

sub add {
  my $self = shift;
  my $value = shift;
  $self->{trie}->add($value);
}

sub start {
  my $self = shift;
  my $query = shift;
  $self->{query} = $query;
  $self->{idx} = 0;
  $self->{suggestions} = $self->{trie}->lookup($query);
  unshift @{$self->{suggestions}}, $self->{query};
}

1;
