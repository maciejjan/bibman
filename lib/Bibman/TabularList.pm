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

package TabularList;

use strict;
use warnings;
use feature 'unicode_strings';
use Curses;
use List::Util qw( min max );

sub new {
  my $class = shift;
  my $self = {
    columns => shift,
    col_widths => undef,
    max_col_widths => [],
    colors => [],
    highlight => 0,
    top => 0,
    items => []
  };
  bless $self, $class;
  $self->reset_col_widths;
  return $self;
}

sub add_item {
  my $self = shift;
  my $values = shift;
  my $item = {
    values => $values,
    visible => 1
  };
  $self->update_col_widths($values);
  push @{$self->{items}}, $item;
}

sub add_item_at {
  my $self = shift;
  my $idx = shift;
  my $values = shift;
  my $item = {
    values => $values,
    visible => 1
  };
  $self->update_col_widths($values);
  splice @{$self->{items}}, $idx, 0, $item;
}

sub update_item {
  my $self = shift;
  my $idx = shift;
  my $values = shift;
  ${$self->{items}}[$idx]->{values} = $values;
  $self->update_col_widths;
}

sub delete_item {
  my $self = shift;
  my $idx = shift;
  splice @{$self->{items}}, $idx, 1;
  $self->update_col_widths;
}

sub delete_all_items {
  my $self = shift;
  $self->{items} = [];
  $self->reset_col_widths;
}

sub reset_col_widths {
  my $self = shift;
  $self->{col_widths} = [];
  for (my $j = 0; $j < $self->{columns}; $j++) {
    ${$self->{col_widths}}[$j] = 0;
  }
}

sub update_col_widths {
  my $self = shift;
  my $values = shift;
  # if called without a parameter -> check all items
  if (!defined($values)) {
    $self->reset_col_widths;
    for my $item (@{$self->{items}}) {
      $self->update_col_widths($item->{values});
    }
    # if max widths are set -> take them into account
    for (my $j = 0; $j < $self->{columns}; $j++) {
      my $mw = $self->{max_col_widths}->[$j];
      if (defined($mw) && ($mw > 0)) {
        $self->{col_widths}->[$j] = min($self->{col_widths}->[$j], $mw);
      }
    }
  } 
  # else check for one item
  else {
    for (my $j = 0; $j < $self->{columns}; $j++) {
      ${$self->{col_widths}}[$j] = max(${$self->{col_widths}}[$j],
                                       length ${$values}[$j]);
    }
  }
}

sub put_item {
  my ($self, $y, $x, $hl, $item) = @_;
  my @formatted_line = ();
  my $length = 0;
  my $cx = 0;
  $hl && $self->{win}->attron(A_REVERSE);
  for (my $i = 0; $i <= $#{$item->{values}}; $i++) {
    my $value = length($item->{values}->[$i]) <= $self->{col_widths}->[$i] ?
                $item->{values}->[$i] :
                substr(${$item->{values}}[$i], 0, $self->{col_widths}->[$i]-1) . "+";
    $value = substr($value, 0, $self->{width}-$cx);
    if ((!$hl) && (defined($self->{colors}->[$i]))) {
      $self->{win}->attron(COLOR_PAIR($self->{colors}->[$i]));
    }
    $self->{win}->addstring($y, $cx, $value);
    if ((!$hl) && (defined($self->{colors}->[$i]))) {
      $self->{win}->attroff(COLOR_PAIR($self->{colors}->[$i]));
    }
    $cx += length $value;
    last if ($cx == $self->{width});
    if ($i < $#{$item->{values}}) {
      my $spacing_length = $self->{col_widths}->[$i] + 1 - length $value;
      $self->{win}->addstring($y, $cx, " " x $spacing_length);
      $cx += $spacing_length;
    }
  }
  my $trailing_length = $self->{width} - $cx;
  $self->{win}->addstring($y, $cx, " " x $trailing_length);
  $hl && $self->{win}->attroff(A_REVERSE);
}

sub center {
  my $self = shift;
  my $new_top = $self->{highlight} - int($self->{height}/2);
  if ($new_top < 0) { $new_top = 0; }
  $self->{top} = $new_top;
  $self->redraw;
}

sub go_up {
  my $self = shift;
  $self->go_to_item($self->prev_visible($self->{highlight}-1));
}

sub go_down {
  my $self = shift;
  $self->go_to_item($self->next_visible($self->{highlight}+1));
}

sub go_page_up {
  my $self = shift;
  if ($self->{highlight} - $self->{height} < 0) {
    $self->go_to_first();
  } else {
    $self->{highlight} -= $self->{height};
    my $new_top = $self->{top} - $self->{height};
    if ($new_top < 0) { $new_top = 0; }
    $self->{top} = $new_top;
    $self->redraw;
  }
}

sub go_page_down {
  my $self = shift;
  if ($self->{highlight} + $self->{height} > $#{$self->{items}}) {
    $self->go_to_last();
  } else {
    $self->{highlight} += $self->{height};
    my $new_top = $self->{top} + $self->{height};
    if ($new_top + $self->{height} > $#{$self->{items}}) {
      $new_top = $#{$self->{items}} - $self->{height};
    }
    $self->{top} = $new_top;
    $self->redraw;
  }
}

sub go_to_first {
  my $self = shift;
  $self->go_to_item($self->next_visible(0));
}

sub go_to_last {
  my $self = shift;
  $self->go_to_item($self->prev_visible($#{$self->{items}}));
}

sub next_visible {
  my $self = shift;
  my $idx = shift;
  while (($idx <= $#{$self->{items}}) && (!${$self->{items}}[$idx]->{visible})) {
    $idx++;
  }
  if ($idx <= $#{$self->{items}}) {
    return $idx;
  } else {
    return undef;
  }
}

sub prev_visible {
  my $self = shift;
  my $idx = shift;
  while (($idx >= 0) && (!${$self->{items}}[$idx]->{visible})) {
    $idx--;
  }
  if ($idx >= 0) {
    return $idx;
  } else {
    return undef;
  }
}

sub go_to_item {
  my $self = shift;
  my $idx = shift;
  if (defined($idx)) {
    $self->{highlight} = $idx;
    $self->redraw;
  }
}

sub draw {
  my $self = shift;
  $self->{win} = shift;
  $self->{x} = shift;
  $self->{y} = shift;
  $self->{width} = shift;
  $self->{height} = shift;
  $self->redraw;
}

sub redraw {
  my $self = shift;
  my $win = $self->{win};

  $self->correct_top;
  my $cur_y = 0;
  my $idx = $self->next_visible($self->{top});
  while (defined($idx) && ($cur_y <= $self->{height}) && ($idx <= $#{$self->{items}})) {
    $self->put_item($cur_y, 0, ($self->{highlight} == $idx), $self->{items}->[$idx]);
    $cur_y++;
    $idx = $self->next_visible(++$idx);
  }
}

# make sure that the highlighted item is visible
sub correct_top {
  my $self = shift;
  my $new_top = $self->{highlight};
  my $num_entries = 0;
  # set the highlight to at least the old top (or lower if needed)
  while (($num_entries < $self->{height}) && ($new_top > $self->{top})) {
    my $new_new_top = $self->prev_visible($new_top-1);
    last if (!defined($new_new_top));
    $new_top = $new_new_top;
    $num_entries++;
  }
  # count the entries below the highlight
  my $idx = $self->next_visible($self->{highlight});
  while ((defined($idx)) && ($idx < $#{$self->{items}}) && ($num_entries < $self->{height})) {
    $idx = $self->next_visible($idx+1);
    $num_entries++;
  }
  # if necessary, lift the top further up
  while ($num_entries < $self->{height}) {
    my $new_new_top = $self->prev_visible($new_top-1);
    last if (!defined($new_new_top));
    $new_top = $new_new_top;
    $num_entries++;
  }
  $self->{top} = $new_top;
}

1;
