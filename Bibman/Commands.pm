use Curses;

package CmdQuit {
  sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
  }

  sub exec {
    my $self = shift;
    endwin;
    exit 0;
  }
}

1;
