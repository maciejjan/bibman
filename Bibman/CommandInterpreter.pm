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

use Bibman::EditScreen;

sub new {
  my $class = shift;
  my $self = {
    model => new Bibliography(),
    mainscr => shift,
    commands => {
      add => { do => \&do_add, undo => \&undo_add },
      delete => { do => \&do_delete, undo => \&undo_delete },
      edit => { do => \&do_edit, undo => \&undo_edit },
      'go-down' => { do => \&do_go_down },
      'go-to-first' => { do => \&do_go_to_first },
      'go-to-last' => { do => \&do_go_to_last },
      'go-up' => { do => \&do_go_up },
      'move-down' => { do => \&do_move_down, undo => \&undo_move_down },
      'move-up' => { do => \&do_move_up, undo => \&undo_move_up },
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
  splice @{$self->{undo_list}}, $self->{undo_pos}+1;
  push @{$self->{undo_list}}, $cmd;
  $self->{undo_pos}++;
}

sub redo {
}

sub do_add {
  my $self = shift;
  my $cmd = shift;
  my $editscr = new EditScreen({ entry_type => "article" });
  my $properties = $editscr->show($self->{mainscr}->{win});
  my $new_entry = $self->{model}->create_entry($properties);
  $self->{model}->add_entry_at($cmd->{hl_idx}+1, $new_entry);
  $self->{mainscr}->{list}->add_item_at($cmd->{hl_idx}+1, format_entry($new_entry));
  $self->{mainscr}->{list}->redraw;
  $self->{mainscr}->{list}->go_up;
  return 1;
}

sub undo_add {
  my $self = shift;
  my $cmd = shift;
  $self->{model}->delete_entry($cmd->{hl_idx}+1);
}

# TODO return 0 if nothing changed
sub do_edit {
  my $self = shift;
  my $cmd = shift;
  my $editscr = new EditScreen(Bibliography::get_properties($cmd->{hl_entry}));
  my $properties = $editscr->show($self->{mainscr}->{win});
  my $updated_entry = $self->{model}->create_entry($properties);
  $self->{model}->replace_entry_at($cmd->{hl_idx}, $updated_entry);
  $self->{mainscr}->{list}->update_item($cmd->{hl_idx}, format_entry($updated_entry));
  $self->{mainscr}->{list}->redraw;
  return 1;
}

sub undo_edit {
  my $self = shift;
  my $cmd = shift;
  $self->{model}->replace_entry_at($cmd->{hl_idx}, $cmd->{hl_entry});
  $self->{mainscr}->{list}->update_item($cmd->{hl_idx}, format_entry($cmd->{hl_entry}));
  $self->{mainscr}->{list}->redraw;
  $self->{mainscr}->{list}->go_to_item($cmd->{hl_idx});
  return 1;
}

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
  $self->{mainscr}->{list}->go_to_item($cmd->{hl_idx});
  return 1;
}

sub do_move_up {
  my $self = shift;
  my $cmd = shift;
  my $idx = $cmd->{hl_idx};
  my $entry = $cmd->{hl_entry};
  if ($idx <= 0) {
    return 0;
  }
  my $entry_above = $self->{model}->get($idx-1);
  $self->{model}->replace_entry_at($idx, $entry_above);
  $self->{model}->replace_entry_at($idx-1, $entry);
  $self->{mainscr}->{list}->update_item($idx, format_entry($entry_above));
  $self->{mainscr}->{list}->update_item($idx-1, format_entry($entry));
  $self->{mainscr}->{list}->redraw;
  $self->{mainscr}->{list}->go_up;
  return 1;
}

sub undo_move_up {
  my $self = shift;
  my $cmd = shift;
  $cmd->{hl_idx}--;
  do_move_down($self, $cmd);
  $self->{mainscr}->{list}->go_to_item($cmd->{hl_idx}+1);
}

sub do_move_down {
  my $self = shift;
  my $cmd = shift;
  my $idx = $cmd->{hl_idx};
  my $entry = $cmd->{hl_entry};
  if ($idx >= $#{$self->{model}->{entries}}) {
    return 0;
  }
  my $entry_below = $self->{model}->get($idx+1);
  $self->{model}->replace_entry_at($idx, $entry_below);
  $self->{model}->replace_entry_at($idx+1, $entry);
  $self->{mainscr}->{list}->update_item($idx, format_entry($entry_below));
  $self->{mainscr}->{list}->update_item($idx+1, format_entry($entry));
  $self->{mainscr}->{list}->redraw;
  $self->{mainscr}->{list}->go_down;
  return 1;
}

sub undo_move_down {
  my $self = shift;
  my $cmd = shift;
  $cmd->{hl_idx}++;
  do_move_up($self, $cmd);
  $self->{mainscr}->{list}->go_to_item($cmd->{hl_idx}-1);
}

sub do_go_up {
  my $self = shift;
  my $cmd = shift;
  $self->{mainscr}->{list}->go_up();
}

sub do_go_down {
  my $self = shift;
  my $cmd = shift;
  $self->{mainscr}->{list}->go_down();
}

sub do_go_to_first {
  my $self = shift;
  my $cmd = shift;
  $self->{mainscr}->{list}->go_to_first();
}

sub do_go_to_last {
  my $self = shift;
  my $cmd = shift;
  $self->{mainscr}->{list}->go_to_last();
}

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
