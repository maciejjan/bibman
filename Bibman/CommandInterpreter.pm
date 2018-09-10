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

package CommandInterpreter;

use strict;
use warnings;
use Env;
use File::Basename;

use Bibman::Bibliography;
use Bibman::EditScreen;
use Bibman::StatusBar;
use Bibman::TrieAutocompleter;

my $autocomplete_fields = ["entry_type", "author"];
my $default_viewer = "xdg-open";

sub new {
  my $class = shift;
  my $self = {
    autocompleters => {},
    model => new Bibliography(),
    mainscr => shift,
    commands => {
      add => { do => \&do_add, undo => \&undo_add },
      'backward-search' => { do => \&do_backward_search },
      center => { do => \&do_center },
      delete => { do => \&do_delete, undo => \&undo_delete },
      edit => { do => \&do_edit, undo => \&undo_edit },
      filter => { do => \&do_filter },
      'go-down' => { do => \&do_go_down },
      'go-to-first' => { do => \&do_go_to_first },
      'go-to-last' => { do => \&do_go_to_last },
      'go-up' => { do => \&do_go_up },
      'move-down' => { do => \&do_move_down, undo => \&undo_move_down },
      'move-up' => { do => \&do_move_up, undo => \&undo_move_up },
      open => { do => \&do_open },
      'open-entry' => { do => \&do_open_entry },
      save => { do => \&do_save },
      search => { do => \&do_search },
      'search-next' => { do => \&do_search_next },
      'search-prev' => { do => \&do_search_prev },
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
  } else {
    $self->error("Unknown command: $cmd->{name}");
  }
}

sub error {
  my $self = shift;
  my $msg = shift;
  $self->{mainscr}->{status}->set($msg, StatusBar::ERROR);
}

sub info {
  my $self = shift;
  my $msg = shift;
  $self->{mainscr}->{status}->set($msg, StatusBar::INFO);
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

sub make_autocompleters {
  my $self = shift;
  $self->{autocompleters} = {};
  for my $field (@$autocomplete_fields) {
    $self->{autocompleters}->{$field} = new TrieAutocompleter();
  }
  for my $entry (@{$self->{model}->{entries}}) {
    for my $field (@$autocomplete_fields) {
      my @values = split /\s/, Bibliography::get_property($entry, $field);
      for my $value (@values) {
        $self->{autocompleters}->{$field}->add($value);
      }
    }
  }
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
  for my $field (@$autocomplete_fields) {
    if (defined($editscr->{inputs}->{$field})) {
      $editscr->{inputs}->{$field}->{autocompleter} =
        $self->{autocompleters}->{$field};
    }
  }
  my $properties = $editscr->show($self->{mainscr}->{win});
  $self->{mainscr}->draw;
  my $new_entry = $self->{model}->create_entry($properties);
  $self->{model}->add_entry_at($cmd->{hl_idx}+1, $new_entry);
  $self->{mainscr}->{list}->add_item_at($cmd->{hl_idx}+1, format_entry($new_entry));
  $self->{mainscr}->{list}->redraw;
  $self->{mainscr}->{list}->go_down;
  return 1;
}

sub undo_add {
  my $self = shift;
  my $cmd = shift;
  $self->{model}->delete_entry($cmd->{hl_idx}+1);
  $self->{mainscr}->{list}->delete_item($cmd->{hl_idx}+1);
  $self->{mainscr}->{list}->redraw;
  $self->{mainscr}->{list}->go_to_item($cmd->{hl_idx});
}

sub do_center {
  my $self = shift;
  my $cmd = shift;
  $self->{mainscr}->{list}->center();
}

sub do_edit {
  my $self = shift;
  my $cmd = shift;
  my $editscr = new EditScreen(Bibliography::get_properties($cmd->{hl_entry}));
  for my $field (@$autocomplete_fields) {
    if (defined($editscr->{inputs}->{$field})) {
      $editscr->{inputs}->{$field}->{autocompleter} =
        $self->{autocompleters}->{$field};
    }
  }
  my $properties = $editscr->show($self->{mainscr}->{win});
  my $old_properties = Bibliography::get_properties($cmd->{hl_entry});
  $self->{mainscr}->draw;

  # return 0 if nothing changed
  if ($properties->{entry_type} eq $old_properties->{entry_type}) {
    my @fields = @{Bibliography::get_fields_for_type($properties->{entry_type})};
    my $equal = 1;
    for my $field (@fields) {
      if (!defined($properties->{$field}) && (!defined($old_properties->{$field}))) {
        next;
      } elsif (!defined($properties->{$field}) || (!defined($old_properties->{$field}))) {
        $equal = 0;
        last;
      } elsif ($properties->{$field} ne $old_properties->{$field}) {
        $equal = 0;
        last;
      }
    }
    if ($equal) {
      return 0;
    }
  }

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
  if (!defined($self->{mainscr}->{list}->next_visible($cmd->{hl_idx}))) {
    $self->{mainscr}->{list}->go_up;
  }
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
  $self->make_autocompleters();
  $self->update_view();
  return 1;
}

sub do_open_entry {
  my $self = shift;
  my $cmd = shift;
  my $dir = dirname($self->{model}->{filename});
  my $key = $cmd->{hl_entry}->key;
  my $filename =  "$dir/$key.pdf";
  my $viewer = $default_viewer;
  if (defined($ENV{BIBMAN_VIEWER})) {
    $viewer = $ENV{BIBMAN_VIEWER};
  }
  if (-e $filename) {
    if (fork == 0) {
      exec "$viewer $filename";
    }
  } else {
    $self->error("File not found: $filename");
  }
}

sub do_save {
  my $self = shift;
  my $cmd = shift;
  if ($#{$cmd->{args}} > -1) {
    $self->{model}->{filename} = ${$cmd->{args}}[0];
  }
  $self->{model}->write;
  $self->info("Saved to $self->{model}->{filename}.");
}

sub match {
  my $self = shift;
  my $idx = shift;
  my $field = shift;
  my $pattern = shift;
  if (!defined($pattern)) {
    $field = $self->{search_args}->{field};
    $pattern = $self->{search_args}->{pattern};
  }
  my $entry = $self->{model}->get($idx);
  if (defined($field)) {
    my $value = Bibliography::get_property($entry, $field);
    if ((defined($value)) && ($value =~ /$pattern/)) {
      return 1;
    }
  } else {
    for (my $i = 0; $i < $self->{mainscr}->{list}->{columns}; $i++) {
      my $list_item = ${$self->{mainscr}->{list}->{items}}[$idx];
      if (${$list_item->{values}}[$i] =~ /$pattern/) {
        return 1;
      }
    }
  }
  return 0;
}

sub parse_search_args {
  if ($#_ > 0) {
    return $_[0], $_[1];
  } else {
    return undef, $_[0];
  }
}

sub set_search_args {
  my $self = shift;
  my ($field, $pattern) = parse_search_args(@_);
  if (defined($pattern)) {
    $self->{search_args} = { field => $field, pattern => $pattern};
  } else {
    $self->{search_args} = undef;
  }
}

sub do_search {
  my $self = shift;
  my $cmd = shift;
  $self->set_search_args(@{$cmd->{args}});
  do_search_next($self, $cmd);
}

sub do_backward_search {
  my $self = shift;
  my $cmd = shift;
  $self->set_search_args(@{$cmd->{args}});
  do_search_prev($self, $cmd);
}

sub do_search_next {
  my $self = shift;
  my $cmd = shift;
  if (!defined($self->{search_args})) {
    return 0;
  }
  my $idx = $self->{mainscr}->{list}->{highlight};
  do {
    $idx++;
    if ($idx > $#{$self->{mainscr}->{list}->{items}}) {
      $idx = 0;
    }
    $idx = $self->{mainscr}->{list}->next_visible($idx);
    if (!defined($idx)) {
      $idx = $self->{mainscr}->{list}->next_visible(0);
    }
  } while (!($self->match($idx) || $idx == $self->{mainscr}->{list}->{highlight}));
  $self->{mainscr}->{list}->go_to_item($idx);
  return 1;
}

sub do_search_prev {
  my $self = shift;
  my $cmd = shift;
  if (!defined($self->{search_args})) {
    return 0;
  }
  my $idx = $self->{mainscr}->{list}->{highlight};
  do {
    $idx--;
    if ($idx < 0) {
      $idx = $#{$self->{mainscr}->{list}->{items}};
    }
    $idx = $self->{mainscr}->{list}->prev_visible($idx);
    if (!defined($idx)) {
      $idx = $self->{mainscr}->{list}->prev_visible($#{$self->{mainscr}->{list}->{items}});
    }
  } while (!($self->match($idx) || $idx == $self->{mainscr}->{list}->{highlight}));
  $self->{mainscr}->{list}->go_to_item($idx);
  return 1;
}

sub do_filter {
  my $self = shift;
  my $cmd = shift;
  my ($field, $pattern) = parse_search_args(@{$cmd->{args}});
  if (!defined($pattern) || (!$pattern)) {
    for my $item (@{$self->{mainscr}->{list}->{items}}) {
      $item->{visible} = 1;
    }
  } else {
    for (my $i = 0; $i <= $#{$self->{model}->{entries}}; $i++) {
      my $item = ${$self->{mainscr}->{list}->{items}}[$i];
      if ($self->match($i, $field, $pattern)) {
        $item->{visible} = 1;
      } else {
        $item->{visible} = 0;
      }
    }
  }
  my $list = $self->{mainscr}->{list};
  my $idx = $list->next_visible($list->{highlight});
  if (!defined($idx)) {
    $idx = $list->prev_visible($list->{highlight});
  }
  $list->go_to_item($idx);
  $self->{mainscr}->draw;
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
