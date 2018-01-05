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

package KeybindingHandler;

use strict;
use warnings;

sub new {
  my $class = shift;
  my $self = {
    cmdmgr => shift,
    bindings => {
      "d" => "delete",
      "u" => "undo",
      "q" => "quit"
    }
  };
  bless $self, $class;
}

sub translate_key {
  my $self = shift;
  my $c = shift;
  my $key = shift;
  if (defined($c)) {
    return $c;
  }
}

sub handle_keypress {
  my $self = shift;
  my $c = shift;
  my $key = shift;
  my $key_tr = $self->translate_key($c, $key);
  if ((defined($key_tr)) && (defined($self->{bindings}->{$key_tr}))) {
    my $cmdline = $self->{bindings}->{$key_tr};
    $self->{cmdmgr}->execute($cmdline);
  }
}

1;
