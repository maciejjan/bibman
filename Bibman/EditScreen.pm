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

package EditScreen;

use strict;
use warnings;
use feature 'unicode_strings';
use Curses;
use List::Util qw( min max );

use Bibman::Bibliography;
use Bibman::StatusBar;
use Bibman::TextInput;

my $autocomplete_fields = ["author", "booktitle", "journal"];

sub new {
  my $class = shift;
  my $self = {
    properties => shift,
    fields => undef,
    focus => undef,
    inputs => undef,
    height => undef,
    left_col_width => undef,
    model => undef,
    status => new StatusBar(),
    highlight => 0,
    top => 0
  };
  $self->{fields} = Bibliography::get_fields_for_type($self->{properties}->{entry_type});
  reset_inputs($self);
  bless $self, $class;
}

sub init_completion {
  my $self = shift;
  my $model = shift;

  $self->{model} = $model;
  # autocompletion
  $self->{inputs}->{entry_type}->{completion}->{get_suggestions} =
    Bibliography::entry_type_completer();
  for my $field (@$autocomplete_fields) {
    if (defined($self->{inputs}->{$field})) {
      $self->{inputs}->{$field}->{completion}->{get_suggestions} =
        $model->field_completer($field);
    }
  }
}

sub reset_inputs {
  my $self = shift;
  $self->{inputs} = {};
  $self->{left_col_width} = 0;
  for my $field (@{$self->{fields}}) {
    $self->{left_col_width} = max($self->{left_col_width}, length $field);
    my $value = $self->{properties}->{$field};
    if (!defined($value)) { 
      $value = "";
    }
    $self->{inputs}->{$field} = new TextInput($value);
  }
}

sub draw {
  my $self = shift;
  $self->{win}->erase;
  my ($maxy, $maxx);
  $self->{win}->getmaxyx($maxy, $maxx);
  $self->{height} = $maxy-2;
  $self->correct_highlight;
  $self->correct_top;
  my $max_idx = min($#{$self->{fields}}, $self->{top} + $self->{height});
  for (my $i = $self->{top}; $i <= $max_idx; $i++) {
    my $field = ${$self->{fields}}[$i];
    my $spaces = " " x ($self->{left_col_width} - length $field);
    if ($i == $self->{highlight}) {
      $self->{win}->attron(A_REVERSE);
    }
    $self->{win}->addstring($i-$self->{top}, 0, $spaces . $field);
    if ($i == $self->{highlight}) {
      $self->{win}->attroff(A_REVERSE);
    }
    my $text_field_size = $maxx - 2 - $self->{left_col_width};
    $self->{inputs}->{$field}->draw($self->{win}, $self->{left_col_width}+1, 
                                    $i-$self->{top}, $text_field_size);
  }
  $self->{status}->draw($self->{win}, $maxy-1);
}

sub correct_top {
  my $self = shift;
  # if the highlight is above the screen -> move up
  if ($self->{highlight} < $self->{top}) {
    $self->{top} = $self->{highlight};
  }
  # if the highlight is below the screen -> move down
  elsif ($self->{highlight} > $self->{top} + $self->{height}) {
    $self->{top} = $self->{highlight}-$self->{height};
  }
  # if there is empty space below -> move up
  if ($self->{highlight} - $self->{top} + $self->{height} > $#{$self->{fields}}) {
    $self->{top} = max(0, $#{$self->{fields}}-$self->{height});
  }
}

sub change_type {
  my $self = shift;
  my $new_type = shift;
  $self->{fields} = Bibliography::get_fields_for_type($new_type);
  $self->{properties}->{entry_type} = $new_type;
  $self->reset_inputs;
  if (defined($self->{model})) {
    $self->init_completion($self->{model});
  }
}

sub go_up {
  my $self = shift;
  $self->{highlight}--;
  $self->draw;
}

sub go_down {
  my $self = shift;
  $self->{highlight}++;
  $self->draw;
}

sub correct_highlight {
  my $self = shift;
  if ($self->{highlight} < 0) {
    $self->{highlight} = 0;
  } elsif ($self->{highlight} > $#{$self->{fields}}) {
    $self->{highlight} = $#{$self->{fields}};
  }
}

sub show {
  my $self = shift;
  my $win = shift;

  $self->{win} = $win;
  $self->draw;

  while (1) {
    my ($c, $key) = $win->getchar();

    if (defined($key) && ($key == KEY_RESIZE)) {
        $self->draw;
    } else {
      my $focus = $self->{focus};
      if (defined($focus)) {
        if (defined($c) && ($c eq "\n")) {
          if ($focus eq "entry_type") {
            my $new_type = $self->{inputs}->{$focus}->{value};
            if (Bibliography::has_type($new_type)) {
              $self->change_type($new_type);
              $self->draw;
            } else {
              $self->{status}->set("Unknown type: $new_type", StatusBar::ERROR);
              $self->{inputs}->{$focus}->set_value($self->{properties}->{entry_type});
            }
          } else {
            $self->{properties}->{$focus} = $self->{inputs}->{$focus}->{value};
          }
          $self->{inputs}->{$focus}->go_to_first;
          if (defined($self->{inputs}->{$focus}->{completion})) {
            $self->{inputs}->{$focus}->reset_completion;
          }
          $self->{focus} = undef;
          curs_set(0);
        } elsif (defined($key) && ($key eq KEY_EXIT)) {
          $self->{focus} = undef;
          curs_set(0);
        } else {
          $self->{inputs}->{$self->{focus}}->key_pressed($c, $key);
        }
      } else {
        if (defined($c)) {
          if ($c eq 'k') {
            $self->go_up;
          } elsif ($c eq 'j') {
            $self->go_down;
          } elsif ($c eq "\n") {
            $self->{focus} = ${$self->{fields}}[$self->{highlight}];
            $self->{inputs}->{$self->{focus}}->go_to_last;
            curs_set(1);
            $self->{inputs}->{$self->{focus}}->redraw;
          } elsif ($c eq 'q') {
            return $self->{properties};
          }
        } elsif (defined($key)) {
          if ($key == KEY_UP) {
            $self->go_up;
          } elsif ($key == KEY_DOWN) {
            $self->go_down;
          }
        }
      }
    }
  }
}

1;
