package TextInput;

use strict;
use warnings;
use feature 'unicode_strings';
use Curses;

sub new {
  my $class = shift;
  my $value = shift;
  my $self = {
    value => $value,
  };
  bless $self, $class;
}

sub draw {
  my $self = shift;
  $self->{win} = shift;
  $self->{x} = shift;
  $self->{y} = shift;
  $self->{size} = shift;
  $self->{pos} = length $self->{value};
  $self->redraw;
}

sub redraw {
  my $self = shift;
  $self->{win}->move($self->{y}, $self->{x});
  $self->{win}->clrtoeol;
  $self->{win}->addstring($self->{value});
  $self->{win}->move($self->{y}, $self->{x} + $self->{pos});
}

sub set_value {
  my $self = shift;
  my $value = shift;
  $self->{value} = $value;
  $self->{pos} = length $value;
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
