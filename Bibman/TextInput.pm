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
    left => 0
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

sub key_pressed {
  my $self = shift;
  my $c = shift;
  my $key = shift;

  if (defined($c)) {
    substr($self->{value}, $self->{pos}, 0) = $c;
    $self->{pos}++;
  } elsif (defined($key)) {
    if ($key == KEY_BACKSPACE) {
      if ($self->{pos} > 0) {
        $self->{value} = substr($self->{value}, 0, $self->{pos}-1)
                         . substr($self->{value}, $self->{pos});
        $self->{pos}--;
      }
    }
    elsif ($key == KEY_DC) {
      if ($self->{pos} < length $self->{value}) {
        $self->{value} = substr($self->{value}, 0, $self->{pos})
                         . substr($self->{value}, $self->{pos}+1);
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
