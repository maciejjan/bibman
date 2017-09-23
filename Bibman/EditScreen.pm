package EditScreen;

use strict;
use warnings;
use Curses;
use List::Util qw( min max );

use FindBin qw($Bin);
use lib "$Bin/.";
use Bibman::Bibliography;

sub new {
  my $class = shift;
  my $self = {
    type => shift,
    properties => shift,
    highlight => 0
  };
  $self->{left_col_width} = 0;
  for my $field (@$Bibliography::fields{$self->{type}}) {
    $self->{left_col_width} = max($self->{left_col_width}, length $field);
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
    my $value = $self->{properties}->{$field};
    if (defined($value)) {
      $self->{win}->addstring($i, $self->{left_col_width}+1, $value);
    }
    $self->{win}->clrtoeol;
    if ($i == $self->{highlight}) {
      $self->{win}->attroff(A_REVERSE);
    }
  }
}

sub go_up {
  my $self = shift;
  $self->{highlight}--;
}

sub go_down {
  my $self = shift;
  $self->{highlight}++;
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
    if (defined($c)) {
      if ($c eq 'k') {
        $self->go_up;
        $self->draw;
      } elsif ($c eq 'j') {
        $self->go_down;
        $self->draw;
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

1;
