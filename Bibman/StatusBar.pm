# This file is part of Bibman -- a console tool for managing BibTeX files.
# Copyright 2017, Maciej Sumalvico <macjan@o2.pl>

# Bibman is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Bibman is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Bibman. If not, see <http://www.gnu.org/licenses/>.

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
