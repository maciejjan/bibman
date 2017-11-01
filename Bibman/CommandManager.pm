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

package CommandManager;

use strict;
use warnings;
use feature 'unicode_strings';

# TODO
# class CommandManager
# - command properties:
#   - name
#   - arguments (type: file / oneof / string)
#   - command class
# - register
# - autocomplete (in a separate class!)
#   - "complete" function reference as a field of TextInput
#     - input: string (the current value) -- or only the last token?!
#     - output: a list of strings (value proposals)
#     - TextInput implements cycling through completion proposals
# - each command implements the following methods:
#   - execute
#   - undo
#
# usage example:
# cmdmgr = new CommandManager;
# cmdmgr.register({name => 'quit', args => []});
# cmdmgr.register({name => '');
# cmdmgr.instance({name => 'save', args => ['bibliography.bib']});

sub new {
  my $class = shift;
  my $self = {
    commands => {}
  };
  bless $self, $class;
}

sub register {
  my $self = shift;
  my $cmd_data = shift;

  if (!defined($cmd_data->{name})) {
    # TODO exception
  }
  if (!defined($cmd_data->{args})) {
    # TODO exception
  }
  if (!defined($cmd_data->{class})) {
    # TODO exception
  }

  if (!defined($self->{commands}->{$cmd_data->{name}})) {
    $self->{commands}->{$cmd_data->{name}} = [];
  }
  push @{$self->{commands}->{$cmd_data->{name}}}, $cmd_data;
}

# parses a command line and returns a relevant Command object
sub call {
  my $self = shift;
  my $cmdline = shift;

  my @args = split(/\s+/, $cmdline);

  if (!defined($self->{commands}->{$args[0]})) {
    # TODO exception
  }
  my $cmd_data = ${$self->{commands}->{$args[0]}}[0];
  # TODO find the right Command object for this call

  my $class = $cmd_data->{class};
  return &$class();
}

#
sub autocomplete {
  my $self = shift;
  my $cmdline = shift;  # the current command line
  my $pos = shift;      # cursor position
  # TODO
  die "Not implemented!";
}

1;
