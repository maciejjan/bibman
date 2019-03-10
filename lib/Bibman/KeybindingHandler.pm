# This file is part of Bibman -- a console tool for managing BibTeX files.
# Copyright 2017-2018, Maciej Sumalvico <macjan@o2.pl>

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

use Bibman::StatusBar;

sub new {
  my $class = shift;
  my $self = {
    parent => shift,
    bindings => {
      "a"    => "add\n",
      "d"    => "delete\n",
      "e"    => "edit\n",
      "f"    => "filter ",
      "g"    => "go-to-first\n",
      "G"    => "go-to-last\n",
      "j"    => "go-down\n",
      "J"    => "page-down\n",
      "k"    => "go-up\n",
      "K"    => "page-up\n",
      "n"    => "search-next\n",
      "N"    => "search-prev\n",
      "o"    => "open-entry\n",
      "O"    => "open ",
      "s"    => "save\n",
      "S"    => "save ",
      "u"    => "undo\n",
      "p"    => "paste\n",
      "q"    => "quit\n",
      "y"    => "yank\n",
      "z"    => "center\n",
      "+"    => "move-down\n",
      "-"    => "move-up\n",
      "/"    => "search ",
      "?"    => "backward-search ",
      "<CR>" => "open-entry\n"
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
    # performance optimization -- if the command ends in a newline,
    # don't type it into the command line, but execute directly
    if ($cmdline =~ m/\n$/gm) {
      chomp($cmdline);
      $self->{parent}->{cmdinterp}->execute($cmdline);
    } else {
      $self->{parent}->enter_command_mode;
      for my $c (split "", $cmdline) {
        $self->{parent}->key_pressed($c, undef);
      }
    }
  }
}

1;
