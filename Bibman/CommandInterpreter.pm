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

package CommandInterpreter;

use strict;
use warnings;

sub new {
  my $class = shift;
  my $self = {
    model => new Bibliography(),
    mainscr => shift,
    commands => {
#       add => { do => \&do_add, undo => \&undo_add },
      delete => { do => \&do_delete, undo => \&undo_delete },
#       edit => { do => \&do_edit, undo => \&undo_edit },
      open => { do => \&do_open },
      undo => { do => \&do_undo },
      quit => { do => \&do_quit },
    },
    undo_pos => -1,
    undo_list => []
  };
  bless $self, $class;
  $self->update_view();
  return $self;
}

sub parse_cmdline {
  my $self = shift;
  my $cmdline = shift;
  my @cmdline_spl = split /\s/, $cmdline;
  my $cmd_name = shift @cmdline_spl;
  my $cmd_args = \@cmdline_spl;
  my $hl_idx = $self->{mainscr}->{list}->{highlight};
  my $cmd = {
    name => $cmd_name,
    args => $cmd_args,
    hl_idx => $hl_idx,
    hl_entry => $self->{model}->get($hl_idx)
  };
  return $cmd;
}

sub execute {
  my $self = shift;
  my $cmdline = shift;
  my $cmd = $self->parse_cmdline($cmdline);
  if (defined($self->{commands}->{$cmd->{name}})) {
    my $result = $self->{commands}->{$cmd->{name}}->{do}->($self, $cmd);
    if (($result) && (defined($self->{commands}->{$cmd->{name}}->{undo}))) {
      $self->add_to_undo_list($cmd);
    }
  }
}

sub format_entry {
  my $entry = shift;

  my @list_entry = ();
  if ($entry->key) { push @list_entry, $entry->key; } else { push @list_entry, "unknown"; }
  my $authors = Bibliography::format_authors($entry);
  if ($authors) { push @list_entry, $authors; } else { push @list_entry, "unknown"; }
  my $year = $entry->get('year');
  if ($year) { push @list_entry, $year; } else { push @list_entry, ""; }
  my $title = $entry->get('title');
  if ($title) { push @list_entry, $title; } else { push @list_entry, "unknown"; }
  return \@list_entry;
}

sub update_view {
  my $self = shift;
  my $list = $self->{mainscr}->{list};
  $list->delete_all_items();
  for my $entry (@{$self->{model}->{entries}}) {
    $list->add_item(format_entry($entry));
  }
}

sub add_to_undo_list {
  my $self = shift;
  my $cmd = shift;
#   # TODO also clear everything after undo_pos
  splice @{$self->{undo_list}}, $self->{undo_pos}+1;
  push @{$self->{undo_list}}, $cmd;
  $self->{undo_pos}++;
}

sub redo {
}

# sub do_add {
#   my $self = shift;
#   my $cmd = shift;
#   $new_entry = show_edit_screen();
#   $model->insert($idx+1, $new_entry);
#   $self->update_view();
# }
# 
# sub undo_add {
#   my $self = shift;
#   my $cmd = shift;
#   $view = shift;
#   $model->delete($idx+1);
# }
# 
# sub do_edit {
#   my $self = shift;
#   my $cmd = shift;
#   $updated_entry = show_edit_screen($entry);
#   $model->delete($idx);
#   $model->insert($idx, $updated_entry);
# }
# 
# sub undo_edit {
#   my $self = shift;
#   my $cmd = shift;
#   $model->replace($idx, $entry);
# }

sub do_delete {
  my $self = shift;
  my $cmd = shift;
  $self->{model}->delete_entry($cmd->{hl_idx});
  $self->{mainscr}->{list}->delete_item($cmd->{hl_idx});
  $self->{mainscr}->{list}->redraw;
  return 1;
}

sub undo_delete {
  my $self = shift;
  my $cmd = shift;
  $self->{model}->add_entry_at($cmd->{hl_idx}, $cmd->{hl_entry});
  $self->{mainscr}->{list}->add_item_at($cmd->{hl_idx}, format_entry($cmd->{hl_entry}));
  $self->{mainscr}->{list}->redraw;
  return 1;
}

# # TODO return false if impossible!
# # TODO pass $model
# sub do_move_up {
#   my $self = shift;
#   my $cmd = shift;
#   $entry_above = $model->get($idx-1);
#   $model->replace($idx, $entry_above);
#   $model->replace($idx-1, $entry);
# }
# 
# sub undo_move_up {
#   my $self = shift;
#   my $cmd = shift;
#   do_move_down($idx, $entry);
# }
# 
# sub do_move_down {
#   my $self = shift;
#   my $cmd = shift;
#   $entry_below = $model->get($idx+1);
#   $model->replace($idx, $entry_below);
#   $model->replace($idx+1, $entry);
# }
# 
# sub undo_move_down {
#   my $self = shift;
#   my $cmd = shift;
#   do_move_up($idx, $entry);
# }

# TODO functions operating on the view etc.

sub do_open {
  my $self = shift;
  my $cmd = shift;
  $self->{model} = new Bibliography($cmd->{args}[0]);
  $self->update_view();
  return 1;
}

sub do_undo {
  my $self = shift;
  if ($self->{undo_pos} < 0) {
    return 0;
  }
  my $cmd = ${$self->{undo_list}}[$self->{undo_pos}];
  $self->{commands}->{$cmd->{name}}->{undo}->($self, $cmd);
  $self->{undo_pos}--;
  return 1;
}

sub do_quit {
  my $self = shift;
  my $cmd = shift;
  $self->{mainscr}->quit;
  return 1;
}

1;
