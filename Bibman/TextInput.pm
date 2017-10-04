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

package TextInput;

use strict;
use warnings;
use feature 'unicode_strings';
use Curses;
use List::Util qw( min max );

sub new {
  my $class = shift;
  my $value = shift;
  my $self = {
    value => $value,
    pos => 0,
    left => 0,
    autocomplete => undef
  };
  bless $self, $class;
}

sub draw {
  my $self = shift;
  $self->{win} = shift;
  $self->{x} = shift;
  $self->{y} = shift;
  $self->{size} = shift;
  $self->redraw;
}

sub redraw {
  my $self = shift;
  $self->{win}->move($self->{y}, $self->{x});
  $self->{win}->clrtoeol;
  $self->correct_left;
  my $length = min($self->{size}, length( $self->{value})-$self->{left});
  my $str = substr($self->{value}, $self->{left}, $length);
  $self->{win}->addstring($str);
  $self->{win}->move($self->{y}, $self->{x} + $self->{pos} - $self->{left});
}

sub set_value {
  my $self = shift;
  my $value = shift;
  $self->{value} = $value;
  $self->redraw;
}

sub correct_left {
  my $self = shift;
  my $length = length $self->{value};
  # if cursor too far on the right -> shift right
  if ($self->{left} + $self->{size} < $self->{pos}) {
    $self->{left} = $self->{pos} - $self->{size};
  }
  # else if cursor too far on the left -> shift left
  elsif ($self->{left} > $self->{pos}) {
    $self->{left} = $self->{pos};
  }
  if ($self->{left} + $self->{size} > $length) {
    $self->{left} = max(0, $length-$self->{size});
  }
}

sub go_to_first {
  my $self = shift;
  $self->{pos} = 0;
  $self->redraw;
}

sub go_to_last {
  my $self = shift;
  $self->{pos} = length $self->{value};
  $self->redraw;
}

sub autocomplete_next {
  my $self = shift;
  if (!defined($self->{autocompleter})) { return; }
  my $idx = rindex($self->{value}, " ", $self->{pos});
#   if ($idx == -1) { $idx = 0; }
  if (!defined($self->{autocompleter}->{query})) {
    my $query = substr($self->{value}, $idx+1, $self->{pos}-$idx);
    $self->{autocompleter}->start($query);
  }
  my $suggestion = $self->{autocompleter}->next;
  $self->{value} = substr($self->{value}, 0, $idx+1) . $suggestion
                   . substr($self->{value}, $self->{pos});
  $self->{pos} = $idx + 1 + length $suggestion;
  $self->redraw;
}

sub key_pressed {
  my $self = shift;
  my $c = shift;
  my $key = shift;

  if (defined($c)) {
    if ($c eq "\t") {
      $self->autocomplete_next;
    } else {
      substr($self->{value}, $self->{pos}, 0) = $c;
      $self->{pos}++;
      $self->{autocompleter}->reset;
    }
  } elsif (defined($key)) {
    if ($key == KEY_BACKSPACE) {
      if ($self->{pos} > 0) {
        $self->{value} = substr($self->{value}, 0, $self->{pos}-1)
                         . substr($self->{value}, $self->{pos});
        if (!defined($self->{value})) {
          $self->{value} = "";
        }
        $self->{pos}--;
      }
    }
    elsif ($key == KEY_DC) {
      if ($self->{pos} < length $self->{value}) {
        $self->{value} = substr($self->{value}, 0, $self->{pos})
                         . substr($self->{value}, $self->{pos}+1);
        if (!defined($self->{value})) {
          $self->{value} = "";
        }
      }
    }
    elsif ($key == KEY_END) {
      $self->{pos} = length $self->{value};
    }
    elsif ($key == KEY_HOME) {
      $self->{pos} = 0;
    }
    elsif ($key == KEY_LEFT) {
      if ($self->{pos} > 0) { $self->{pos}--; }
    } elsif ($key == KEY_RIGHT) {
      if ($self->{pos} < length $self->{value}) { $self->{pos}++; }
    }
  }
  $self->redraw;
}

1;
