package EditScreen;

use strict;
use warnings;
use Curses;
use List::Util qw( min max );

use FindBin qw($Bin);
use lib "$Bin/.";
use Bibman::Bibliography;
use Bibman::TextInput;

sub new {
  my $class = shift;
  my $self = {
    type => shift,
    properties => shift,
    focus => undef,
    inputs => {},
    highlight => 0
  };
  $self->{left_col_width} = 0;
  print $self->{type} . "\n";
  for my $field (@{$Bibliography::fields->{$self->{type}}}) {
    $self->{left_col_width} = max($self->{left_col_width}, length $field);
    my $value = $self->{properties}->{$field};
    if (!defined($value)) { 
      $value = "";
    }
    $self->{inputs}->{$field} = new TextInput($value);
  }
  bless $self, $class;
}

sub draw {
  my $self = shift;
  $self->correct_highlight;
  $self->{win}->erase;
  for (my $i = 0; $i <= $#{$Bibliography::fields->{$self->{type}}}; $i++) {
    my $field = ${$Bibliography::fields->{$self->{type}}}[$i];
    my $spaces = " " x ($self->{left_col_width} - length $field);
    if ($i == $self->{highlight}) {
      $self->{win}->attron(A_REVERSE);
    }
    $self->{win}->addstring($i, 0, $spaces . $field);
    if ($i == $self->{highlight}) {
      $self->{win}->attroff(A_REVERSE);
    }
    $self->{inputs}->{$field}->draw($self->{win}, $self->{left_col_width}+1, $i, 20);
  }
  if (defined($self->{focus})) {
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
  } elsif ($self->{highlight} > $#{$Bibliography::fields->{$self->{type}}}) {
    $self->{highlight} = $#{$Bibliography::fields->{$self->{type}}};
  }
}

sub show {
  my $self = shift;
  my $win = shift;

  $self->{win} = $win;
  $self->draw;

  while (1) {
    my ($c, $key) = $win->getchar();
    if (defined($self->{focus})) {
      if (defined($c) && ($c eq "\n")) {
        $self->{focus} = undef;
        curs_set(0);
      } elsif (defined($key) && ($key eq KEY_RESIZE)) {
        $self->draw;
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
          $self->{focus} = ${$Bibliography::fields->{$self->{type}}}[$self->{highlight}];
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

1;
