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

package Trie;

use strict;
use warnings;
use feature 'unicode_strings';


sub new {
  my $class = shift;
  my $self = {
    terminal => 0,
    children => {}
  };
  bless $self, $class;
}

sub insert {
  my $self = shift;
  my $value = shift;
  if (length($value) > 0) {
    my $c = substr($value, 0, 1);
    my $new_value = substr($value, 1);
    if (!defined($self->{children}->{$c})) {
      $self->{children}->{$c} = new Trie;
    }
    $self->{children}->{$c}->insert($new_value);
  } else {
    $self->{terminal} = 1;
  }
}

sub go_to_prefix {
  my $self = shift;
  my $prefix = shift;
  if (length($prefix) > 0) {
    my $c = substr($prefix, 0, 1);
    my $new_prefix = substr($prefix, 1);
    if (defined($self->{children}->{$c})) {
      return $self->{children}->{$c}->go_to_prefix($new_prefix);
    } else {
      return undef;
    }
  } else {
    return $self;
  }
}

sub lookup {
  my $self = shift;
  my $query = shift;
  my @results = ();
  my $node = $self->go_to_prefix($query);
  if (defined($node)) {
    return $node->retrieve($query);
  }
  else {
    return [];
  }
}

sub retrieve {
  my $self = shift;
  my $prefix = shift;
  if (!defined($prefix)) {
    $prefix = "";
  }
  my @results = ();
  if ($self->{terminal}) {
    push @results, $prefix;
  }
  for my $c (sort keys %{$self->{children}}) {
    @results = (@results, @{$self->{children}->{$c}->retrieve($prefix . $c)});
  }
  return \@results;
}

1;
