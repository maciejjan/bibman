# This file is part of Bibman -- a console tool for managing BibTeX files.
# Copyright 2017-2020, Maciej Janicki <macjan@o2.pl>

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

use Bibman::KeybindingHandler;

sub new {
  my $class = shift;
  my $value = shift;
  my $self = {
    value => $value,
    pos => 0,
    left => 0,
    completion => undef
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

sub go_left {
  my $self = shift;
  if ($self->{pos} > 0) {
    $self->{pos}--;
    $self->reset_completion;
  }
}

sub go_right {
  my $self = shift;
  if ($self->{pos} < length $self->{value}) {
    $self->{pos}++;
    $self->reset_completion;
  }
}

sub go_to_first {
  my $self = shift;
  $self->{pos} = 0;
}

sub go_to_last {
  my $self = shift;
  $self->{pos} = length $self->{value};
}

sub backspace {
  my $self = shift;
  if ($self->{pos} > 0) {
    $self->{value} = substr($self->{value}, 0, $self->{pos}-1)
                     . substr($self->{value}, $self->{pos});
    if (!defined($self->{value})) {
      $self->{value} = "";
    }
    $self->{pos}--;
  }
  $self->reset_completion;
}

sub delete_char {
  my $self = shift;
  if ($self->{pos} < length $self->{value}) {
    $self->{value} = substr($self->{value}, 0, $self->{pos})
                     . substr($self->{value}, $self->{pos}+1);
    if (!defined($self->{value})) {
      $self->{value} = "";
    }
  }
}

sub delete_to_first {
  my $self = shift;
  $self->{value} = substr($self->{value}, $self->{pos});
  $self->{pos} = 0;
}

sub delete_to_last {
  my $self = shift;
  $self->{value} = substr($self->{value}, 0, $self->{pos});
}

sub delete_word {
  my $self = shift;
  if ($self->{pos} > 0) {
    my $idx = rindex($self->{value}, " ", $self->{pos}-1)+1;
    while (($idx > 1) &&
           (substr($self->{value}, $idx, $self->{pos}-$idx) =~ m/^\s*$/)) {
      $idx = rindex($self->{value}, " ", $idx-1);
    }
    $self->{value} = substr($self->{value}, 0, $idx)
                     . substr($self->{value}, $self->{pos});
    $self->{pos} = $idx;
  }
}

sub insert {
  my $self = shift;
  my $str = shift;
  substr($self->{value}, $self->{pos}, 0) = $str;
  $self->{pos} += length $str;
  $self->reset_completion;
}

sub start_completion {
  my $self = shift;
  my $query = shift;
  if (!defined($self->{completion})) { return; }
  $self->{completion}->{suggestions} =
    $self->{completion}->{get_suggestions}->($query);
  $self->{completion}->{current} = 0;
}

sub reset_completion {
  my $self = shift;
  if (!defined($self->{completion})) { return; }
  undef $self->{completion}->{suggestions};
  undef $self->{completion}->{current};
}

sub complete_next {
  my $self = shift;

  if (!defined($self->{completion})) { return; }

  my $idx = rindex($self->{value}, " ", $self->{pos});
  # start completion if not already started
  if (!defined($self->{completion}->{suggestions})) {
    my $query = substr($self->{value}, $idx+1, $self->{pos}-$idx);
    $self->start_completion($query);
  }
  # get the current suggestion and set the `current` index to the next one
  my @suggestions = @{$self->{completion}->{suggestions}};
  my $s = $suggestions[$self->{completion}->{current}++];
  if ($self->{completion}->{current} > $#suggestions) {
    $self->{completion}->{current} = 0;
  }
  # insert the suggestion into the text field value
  $self->{value} = substr($self->{value}, 0, $idx+1) . $s
                   . substr($self->{value}, $self->{pos});
  $self->{pos} = $idx + 1 + length $s;
  $self->redraw;
}

sub key_pressed {
  my $self = shift;
  my $key = shift;

  if ($key eq "^A") {
    $self->go_to_first;
  } elsif (($key eq "^B") || ($key eq "<Left>")) {
    $self->go_left;
  } elsif ($key eq "^D") {
    $self->delete_char;
  } elsif ($key eq "^E") {
    $self->go_to_last;
  } elsif (($key eq "^F") || ($key eq "<Right>")) {
    $self->go_right;
  } elsif (($key eq "^H") || ($key eq "<Backspace>")) {
    $self->backspace;
  } elsif ($key eq "^I") {
    $self->complete_next;
  } elsif ($key eq "^K") {
    $self->delete_to_last;
  } elsif ($key eq "^U") {
    $self->delete_to_first;
  } elsif ($key eq "^W") {
    $self->delete_word;
  } else {
    $self->insert($key);
  }
  $self->redraw;
}

1;
