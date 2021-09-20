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
      "a"    => "add",
      "d"    => "delete",
      "e"    => "edit",
      "f"    => ":filter",
      "g"    => "go-to-first",
      "G"    => "go-to-last",
      "j"    => "go-down",
      "J"    => "page-down",
      "k"    => "go-up",
      "K"    => "page-up",
      "n"    => "search-next",
      "N"    => "search-prev",
      "o"    => "open-entry",
      "O"    => ":open",
      "s"    => "save",
      "S"    => ":save",
      "u"    => "undo",
      "p"    => "pipe-from xclip -o",
      "q"    => "quit",
      "y"    => "pipe-to xclip -i",
      "z"    => "center",
      "+"    => "move-down",
      "-"    => "move-up",
      "/"    => ":search",
      "?"    => ":backward-search",
      "<CR>" => "open-entry"
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
        $result = "<CR>";
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
    if ($cmdline =~ m/^:/) {
      $cmdline =~ s/^://;
      $self->{parent}->enter_command_mode;
      for my $c (split "", $cmdline . " ") {
        $self->{parent}->key_pressed($c, undef);
      }
    } else {
      # performance optimization -- if the command doesn't require further
      # input, don't type it into the command line, but execute directly
      $self->{parent}->{cmdinterp}->execute($cmdline);
    }
  }
}

1;
