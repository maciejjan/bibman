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

use Bibman::Commands::CmdSave;
use Bibman::Commands::CmdQuit;

sub new {
  my $class = shift;
  my $self = {
    parent => shift,
    commands => {}
  };
  bless $self, $class;
}

sub register {
  my $self = shift;
  my $cmd_data = shift;

  if (!defined($cmd_data->{name})) {
    # TODO exception
    die "No name supplied for a command!";
  }
  if (!defined($cmd_data->{args})) {
    # TODO exception
    die "No argument structure supplied for the command $cmd_data->{name}!";
  }
  if (!defined($cmd_data->{class})) {
    # TODO exception
    die "No class supplied for the command $cmd_data->{name}!";
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
  my $cmd_name = shift @args;

  if (!defined($self->{commands}->{$cmd_name})) {
    die "Unknown command: $cmd_name";
  }
  my $cmd_data = ${$self->{commands}->{$cmd_name}}[0];
  for my $cmd_data (@{$self->{commands}->{$cmd_name}}) {
    last if (match_args(\@args, $cmd_data->{args}));
  }
#   # TODO find the right Command object for this call
# 
  my $class = $cmd_data->{class};
  return $class->new($self->{parent}, @args);
}

#
sub autocomplete {
  my $self = shift;
  my $cmdline = shift;  # the current command line
  my $pos = shift;      # cursor position
  # TODO
  die "Not implemented!";
}

sub match_args {
  my ($ref_args, $ref_argstruct) = @_;
  my @args = @$ref_args;
  my @argstruct = @$ref_argstruct;
  while (($#args >= 0) && ($#argstruct >= 0)) {
    $arg = shift @args;
    $argtype = shift @argstruct;
    while (($#args < $#argstruct) && ($argtype =~ m/\?.*/g)) {
      $argtype = shift @argstruct;
    }
    # TODO verify the type of $arg
  }
  return 1;
}

1;
