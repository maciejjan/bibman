package StatusBar;

use feature 'unicode_strings';
use Curses;

use constant {
  INFO => 1,
  ERROR => 2
};

sub new {
  my $class = shift;
  my $self = {
    status => "",
    type => INFO
  };
  bless $self, $class;
}

sub draw {
  my $self = shift;
  my $win = shift;
  my $position = shift;
  $self->{win} = $win;
  $self->{position} = $position;
  $self->redraw;
}

sub redraw {
  my $self = shift;
  if (!defined($self->{win})) {
    return;
  }
  $self->{win}->attron(COLOR_PAIR($self->{type}) | A_BOLD);
  $self->{win}->addstring($self->{position}, 0, $self->{status});
  $self->{win}->attroff(COLOR_PAIR($self->{type}) | A_BOLD);
  $self->{win}->clrtoeol();
}

sub set {
  my $self = shift;
  my $status = shift;
  my $type = shift;
  if (!defined($type)) {
    $type = INFO;
  }

  $self->{status} = $status;
  $self->{type} = $type;
  $self->redraw;
}

1;
