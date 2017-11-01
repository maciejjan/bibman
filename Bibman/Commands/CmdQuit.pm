package CmdQuit;

use Curses;

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

# TODO commands are called with a function cmd_xxx, e.g.: cmd_add_entry()
# this function might return a "log", which can be used to undo the command
# 
#
# TODO all operations possible from the command line, e.g.
# :edit 10 author="Sumalvico, Maciej"
# :add 11 key=sumalvico15 entry_type=inproceedings
# the edit screen is only used to prepare the command
#
# bulk editing/adding:
# :edit 10,11,12 entry_type=inproceedings
#
# command context:
# - highlighted item
# - (selection)
# - sorting order (none, field)
#
# additional command: "layout" -- changes the layout of the list
# :set layout=key,author,year,title

1;
