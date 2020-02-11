# This file is part of Bibman -- a console tool for managing BibTeX files.
# Copyright 2017-2020, Maciej Janicki <macjan@o2.pl>

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

use Curses;
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

sub get_key {
  my $win = shift;
  my ($c, $key) = $win->getchar();
  my $result;

  if (defined($c)) {
    my $charcode = ord $c;
    if ($charcode < 32) {
      if ($charcode == 10) {
        $result = "\n";
      } elsif ($charcode == 27) {             # Esc
        timeout($win, 1);
        my ($c2, $key2) = $win->getchar();
        timeout($win, -1);
        if (defined($c2) && (ord($c2) != 27)) {
          $result = "M-".$c2;
        } else {
          $result = "<Esc>";
        }
      } else {
        $result = "^" . chr($charcode+64);
      }
    } elsif ($charcode == 127) {
      $result = "<Del>";
    } else {
      $result = $c;
    }
  } elsif (defined($key)) {
    if ($key == KEY_RESIZE) {
      $result = "<RESIZE>";
    } elsif ($key == KEY_UP) {
      $result = "<Up>";
    } elsif ($key == KEY_DOWN) {
      $result = "<Down>";
    } elsif ($key == KEY_LEFT) {
      $result = "<Left>";
    } elsif ($key == KEY_RIGHT) {
      $result = "<Right>";
    } elsif ($key == KEY_BACKSPACE) {
      $result = "<Backspace>";
    } else {
      $result = "<$key>";
    }
  }
  #if (defined($result)) {
  #  print STDERR $result."\n";
  #}
  return $result;
}

sub handle_key {
  my $self = shift;
  my $key_tr = shift;
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
