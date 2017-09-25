package StatusBar;

use feature 'unicode_strings';

sub new {
  my $class = shift;
  my $self = {
    status => ""
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
  $self->{win}->attron(A_BOLD);
  $self->{win}->addstring($self->{position}, 0, $self->{status});
  $self->{win}->attroff(A_BOLD);
  $self->{win}->clrtoeol();
}

sub set {
  my $self = shift;
  my $status = shift;
  my $type = shift;

  $self->{status} = $status;
  $self->{type} = $type;
  $self->redraw;
}

1;
