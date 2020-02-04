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

package MainScreen;

use strict;
use warnings;
use feature 'unicode_strings';
use Curses;
use File::Basename;

use Bibman::Bibliography;
use Bibman::CommandInterpreter;
use Bibman::KeybindingHandler;
use Bibman::TabularList;
use Bibman::TextInput;
use Bibman::StatusBar;

sub new {
  my $class = shift;
  my $list = new TabularList(4);
  my $self = {
    cmdinterp => undef,
    kbdhandler => undef,
    list   => $list,
    status => new StatusBar(),
    cmd_prompt => new TextInput(""),
    mode   => "normal",               # "normal" or "command"
    filename => undef,
    search_field => undef,
    search_pattern => undef,
    filter_field => undef,
    filter_pattern => undef
  };
  $self->{cmdinterp} = new CommandInterpreter($self);
  $self->{kbdhandler} = new KeybindingHandler($self);
  bless $self, $class;
}

sub quit {
  endwin;
  exit 0;
}

sub draw {
  my $self = shift;
  $self->{win}->erase;
  my ($maxy, $maxx);
  $self->{win}->getmaxyx($maxy, $maxx);
  $self->{list}->draw($self->{win}, 0, 0, $maxx, $maxy-3);
  $self->{status}->draw($self->{win}, $maxy-2);
  if ($self->{mode} eq "command") {
    $self->{win}->addstring($maxy-1, 0, ":");
    $self->{cmd_prompt}->draw($self->{win}, 1, $maxy-1, $maxx-2);
  }
}

sub enter_command_mode {
  my $self = shift;
  my $cmd = shift;
  if (defined($cmd)) {
    $cmd .= " ";
  } else {
    $cmd = "";
  }
  $self->{mode} = "command";
  $self->{cmd_prompt}->{value} = $cmd;
  $self->{cmd_prompt}->{pos} = length $cmd;
  curs_set(1);
  $self->draw;
}

sub exit_command_mode {
  my $self = shift;
  $self->{mode} = "normal";
  curs_set(0);
  $self->draw;
}

sub key_pressed {
  my $self = shift;
  my $key = shift;

  if ($key eq "<RESIZE>") {
    $self->draw;
  } else {
    if ($self->{mode} eq "normal") {
      if ($key eq ':') {
        $self->enter_command_mode;
      } else {
        $self->{kbdhandler}->handle_key($key);
      }
    } elsif ($self->{mode} eq "command") {
      if ((!$self->{cmd_prompt}->{value}) && ($key eq "<Backspace>")) {
        $self->exit_command_mode;
      } elsif ($key eq "\n") {
        $self->exit_command_mode;
        $self->{cmdinterp}->execute($self->{cmd_prompt}->{value});
      } elsif ($key eq "<Esc>") {
        $self->exit_command_mode;
      } else {
        $self->{cmd_prompt}->key_pressed($key);
      }
    }
  }
}

sub show {
  my $self = shift;
  my $win = shift;

  $self->{win} = $win;
  $self->draw;

  while (1) {
    my $key = KeybindingHandler::get_key($win);
    $self->key_pressed($key);
  }
}

1;
