# This file is part of Bibman -- a console tool for managing BibTeX files.
# Copyright 2017-2018, Maciej Sumalvico <macjan@o2.pl>

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

package ListAutocompleter;

use strict;
use warnings;
use feature 'unicode_strings';
use Bibman::Autocompleter;

our @ISA = ("Autocompleter");


sub new {
  my $class = shift;
  my $self = Autocompleter::new(@_);
  $self->{items} = shift;
  bless $self, $class;
}

sub add {
  my $self = shift;
  my $value = shift;
  push $value, @{$self->{items}};
}

sub start {
  my $self = shift;
  my $query = shift;
  $self->{query} = $query;
  $self->{idx} = 0;
  $self->{suggestions} = [];
  for my $item (@{$self->{items}}) {
    if ($item =~ m/^$query/) {
      push $item, @{$self->{suggestions}};
    }
  }
  unshift @{$self->{suggestions}}, $self->{query};
}

1;
