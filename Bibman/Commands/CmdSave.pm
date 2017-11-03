package CmdSave;

use Curses;

sub new {
  my $class = shift;
  my $mainscr = shift;
  my $filename = shift;
  if (!defined($filename)) {
    $filename = $mainscr->{filename};
  }
  my $self = { 
    mainscr => $mainscr, 
    filename => $filename
  };
  bless $self, $class;
  return $self;
}

sub exec {
  my $self = shift;
  $self->{mainscr}->{bibliography}->write($self->{filename});
  $self->{mainscr}->{filename} = $self->{filename};
}

1;
