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
    highlight => 0,
    top => 0,
    items => [],
  };
  bless $self, $class;
  $self->reset_col_widths;
  return $self;
}

sub add_item {
  my $self = shift;
  my $line = shift;
  for (my $i = 0; $i <= $#$line; $i++) {
    ${$self->{col_widths}}[$i] = max(${$self->{col_widths}}[$i], length ${$line}[$i]);
  }
  push @{$self->{items}}, $line;
}

sub update_item {
  my $self = shift;
  my $idx = shift;
  my $item = shift;
  ${$self->{items}}[$idx] = $item;
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
  $self->{col_widths} = [];
  for (my $i = 0; $i < $self->{columns}; $i++) {
    push @{$self->{col_widths}}, 0;
  }
}

sub reset_col_widths {
  my $self = shift;
  $self->{col_widths} = [];
  for (my $j = 0; $j <= $self->{columns}; $j++) {
    ${$self->{col_widths}}[$j] = 0;
  }
}

sub update_col_widths {
  my $self = shift;
  $self->reset_col_widths;
  for (my $i = 0; $i <= $#{$self->{items}}; $i++) {
    for (my $j = 0; $j < $self->{columns}; $j++) {
      ${$self->{col_widths}}[$j] = max(${$self->{col_widths}}[$j],
                                       length ${${$self->{items}}[$i]}[$j]);
    }
  }
}

sub format_item {
  my $self = shift;
  my $line = shift;
  my @formatted_line = ();
  my $length = 0;
  for (my $i = 0; $i < $#$line; $i++) {
    push @formatted_line, $$line[$i];
    my $spacing_length = ${$self->{col_widths}}[$i] + 1 - length $$line[$i];
    push @formatted_line, " " x $spacing_length;
    $length += length($$line[$i]) + $spacing_length;
  }
  push @formatted_line, $$line[$#$line];
  my $trailing_length = $self->{width} - $length;
  if ($trailing_length > 0) {
    push @formatted_line, " " x $trailing_length;
  }
  my $formatted_line_str = join "", @formatted_line;
  if (length $formatted_line_str > $self->{width}) {
    $formatted_line_str = substr $formatted_line_str, 0, $self->{width};
  }
  return $formatted_line_str;
}

sub go_up {
  my $self = shift;
  $self->{highlight}--;
  $self->redraw;
}

sub go_down {
  my $self = shift;
  $self->{highlight}++;
  $self->redraw;
}

sub go_to_first {
  my $self = shift;
  $self->{highlight} = 0;
  $self->redraw;
}

sub go_to_last {
  my $self = shift;
  $self->{highlight} = $#{$self->{items}};
  $self->redraw;
}

sub go_to_item {
  my $self = shift;
  my $idx = shift;
  $self->{highlight} = $idx;
  $self->redraw;
}

sub search {
  my $self = shift;
  my $pattern = shift;
  if ($pattern) {
    $self->{search_pattern} = $pattern;
    return $self->search_next;
  } else {
    return "no pattern";
  }
}

sub search_next {
  my $self = shift;
  if (!defined($self->{search_pattern})) {
    return;
  }
  my $found_idx = undef;
  for (my $i = $self->{highlight}+1;
       $i <= $#{$self->{items}} && !defined($found_idx); 
       $i++) {
    for (my $j = 0;
         $j < $self->{columns} && !defined($found_idx);
         $j++) {
      if (${${$self->{items}}[$i]}[$j] =~ m/$self->{search_pattern}/) {
        $found_idx = $i;
      }
    }
  }
  if (defined($found_idx)) {
    $self->go_to_item($found_idx);
  } else {
    for (my $i = 0;
         $i <= $self->{highlight} && !defined($found_idx); 
         $i++) {
      for (my $j = 0;
           $j < $self->{columns} && !defined($found_idx);
           $j++) {
        if (${${$self->{items}}[$i]}[$j] =~ m/$self->{search_pattern}/) {
          $found_idx = $i;
        }
      }
    }
    if (defined($found_idx)) {
      $self->go_to_item($found_idx);
    } else { 
      return "Pattern: \"$self->{search_pattern}\" not found.";
    }
  }
}

sub search_prev {
}

sub filter {
  my $self = shift;
  my $visible_items =  shift;
  $self->{visible_items} = $visible_items;
  $self->redraw;
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

  $self->correct_highlight;
  $self->correct_top;
  my $cur_y = 0;
  my $max_idx = min($#{$self->{items}}, $self->{top} + $self->{height});
  for (my $i = $self->{top}; $i <= $#{$self->{items}; $i++) {
    next if (!(${$self->{items}}[$i]->{visible}));
    if ($self->{highlight} == $i) {
      $win->attron(A_REVERSE);
    }
    $win->addstring($cur_y, 0, $self->format_item(${$self->{items}}[$i]));
    if ($self->{highlight} == $i) {
      $win->attroff(A_REVERSE);
    }
    $cur_y++;
  }
}

sub correct_highlight {
  my $self = shift;
  if ($self->{highlight} < 0) {
    $self->{highlight} = 0;
  } elsif ($self->{highlight} > $#{$self->{items}}) {
    $self->{highlight} = $#{$self->{items}};
  }
}

# make sure that the highlighted item is visible
sub correct_top {
  my $self = shift;
  if ($self->{highlight} < $self->{top}) {
    $self->{top} = $self->{highlight};
  }
  elsif ($self->{highlight} > $self->{top}+$self->{height}) {
    $self->{top} = $self->{highlight}-$self->{height};
  }
  if ($self->{top} + $self->{height} > $#{$self->{items}}) {
    $self->{top} = max(0, $#{$self->{items}}-$self->{height});
  }
}

1;
