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

package Autocompleter;

use strict;
use warnings;
use feature 'unicode_strings';


sub new {
  my $class = shift;
  my $self = {
    query => undef,
    suggestions => undef,
    idx => undef
  };
  bless $self, $class;
}

sub reset {
  my $self = shift;
  undef $self->{query};
  undef $self->{suggestions};
  undef $self->{idx};
}

sub next {
  my $self = shift;
  $self->{idx}++;
  if ($self->{idx} > $#{$self->{suggestions}}) {
    $self->{idx} = 0;
  }
  return ${$self->{suggestions}}[$self->{idx}];
}


1;
