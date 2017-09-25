package EditScreen;

use strict;
use warnings;
use feature 'unicode_strings';
use Curses;
use List::Util qw( min max );

use FindBin qw($Bin);
use lib "$Bin/.";
use Bibman::Bibliography;
use Bibman::TextInput;

sub new {
  my $class = shift;
  my $self = {
    entry => shift,
    fields => undef,
    key => undef,
    type => undef,
    properties => undef,
    focus => undef,
    inputs => {},
    highlight => 0
  };
  $self->{fields} = $Bibliography::fields->{$self->{entry}->type};
  $self->{properties} = Bibliography::get_properties($self->{entry});
  $self->{left_col_width} = 0;
  for my $field (@{$self->{fields}}) {
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
  for (my $i = 0; $i <= $#{$self->{fields}}; $i++) {
    my $field = ${$self->{fields}}[$i];
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
    if (defined($self->{focus})) {
      if (defined($c) && ($c eq "\n")) {
        $self->{properties}->{$self->{focus}} = $self->{inputs}->{$self->{focus}}->{value};
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
          $self->{focus} = ${$self->{fields}}[$self->{highlight}];
          curs_set(1);
          $self->{inputs}->{$self->{focus}}->redraw;
        } elsif ($c eq 'q') {
          my $entry_text = Bibliography::make_bibtex($self->{entry}->type, 
                                                     $self->{entry}->key,
                                                     $self->{properties});
          $self->{entry}->parse_s($entry_text);
          return;
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
