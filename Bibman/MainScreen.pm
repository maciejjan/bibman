package MainScreen;

use strict;
use warnings;
use feature 'unicode_strings';
use Curses;
use FindBin qw($Bin);
use lib "$Bin/.";
use Bibman::Bibliography;
use Bibman::EditScreen;
use Bibman::TabularList;
use Bibman::TextInput;
use Bibman::StatusBar;

sub new {
  my $class = shift;
  my $self = {
    list   => new TabularList(4),
    status => new StatusBar(),
    cmd_prompt => new TextInput(""),
    mode   => "normal"               # "normal" or "command"
  };
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

sub add_entry {
  my $self = shift;

  my $entry = $self->{bibliography}->add_entry("article");
  my $edit = new EditScreen($entry);
  $edit->show($self->{win});
  $self->{list}->add_item(format_entry($entry));
  $self->draw;
  $self->{list}->go_to_last;
}

sub edit_entry {
  my $self = shift;
  my $idx = $self->{list}->{highlight};
  my $entry = ${$self->{bibliography}->{entries}}[$idx];
  my $edit = new EditScreen($entry);
  $edit->show($self->{win});
  $self->{list}->update_item($idx, format_entry($entry));
  $self->draw;
}

sub delete_entry {
  my $self = shift;
  $self->{bibliography}->delete_entry($self->{list}->{highlight});
  $self->{list}->delete_item($self->{list}->{highlight});
  $self->draw;
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

sub open_bibliography {
  my $self = shift;
  my $filename = shift;

  $self->{list}->delete_all_items;

  $self->{bibliography} = new Bibliography();
  $self->{bibliography}->read($filename);

  for my $entry (@{$self->{bibliography}->{entries}}) {
    $self->{list}->add_item(format_entry($entry));
  }

  my $num_entries = $#{$self->{bibliography}->{entries}}+1;
  $self->{status}->set("Loaded $num_entries entries.");
}

sub save_bibliography {
  my $self = shift;
  my $filename = shift;

  $self->{bibliography}->write($filename);
  my $num_entries = $#{$self->{bibliography}->{entries}}+1;
  $self->{status}->set("Saved $num_entries entries.");
}

sub execute_cmd {
  my $self = shift;
  my $cmdline = shift;

  my @args = split /\s+/, $cmdline;
  my $cmd = shift @args;

  if    ($cmd eq 'add')          { return $self->add_entry(@args);         }
  elsif ($cmd eq 'delete')       { return $self->delete_entry;             }
  elsif ($cmd eq 'edit')         { return $self->edit_entry;               }
  elsif ($cmd eq 'go-up')        { return $self->{list}->go_up;            }
  elsif ($cmd eq 'go-to-first')  { return $self->{list}->go_to_first;      }
  elsif ($cmd eq 'go-down')      { return $self->{list}->go_down;          }
  elsif ($cmd eq 'go-to-last')   { return $self->{list}->go_to_last;       }
  elsif ($cmd eq 'open-entry')   { return "open";                          }
  elsif ($cmd eq 'save')         { $self->save_bibliography(@args);        }
  elsif ($cmd eq 'search')       { return $self->{list}->search(@args);    }
  elsif ($cmd eq 'search-next')  { return $self->{list}->search_next;      }
  elsif ($cmd eq 'quit')         { $self->quit;                            }
  else {
    $self->{status}->set("Unknown command: $cmd");
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
  curs_set(1);
  $self->draw;
}

sub exit_command_mode {
  my $self = shift;
  $self->{mode} = "normal";
  curs_set(0);
  $self->draw;
}

sub show {
  my $self = shift;
  my $win = shift;

  $self->{win} = $win;
  $self->draw;

  while (1) {
    my ($c, $key) = $win->getchar();
    my $cmd = '';
    if (defined($key) && ($key == KEY_RESIZE)) {
      $self->draw;
    }  else {
      if ($self->{mode} eq "normal") {
        if (defined($c)) {
          if ($c eq 'k') {
            $self->execute_cmd('go-up');
          } elsif ($c eq 'j') {
            $self->execute_cmd('go-down');
          } elsif ($c eq 'g') {
            $self->execute_cmd('go-to-first');
          } elsif ($c eq 'G') {
            $self->execute_cmd('go-to-last');
          } elsif ($c eq 'n') {
            $self->execute_cmd('search-next');
          } elsif ($c eq 'a') {
            $self->execute_cmd('add');
          } elsif ($c eq 's') {
            $self->enter_command_mode("save");
          } elsif ($c eq 'd') {
            $self->execute_cmd('delete');
          } elsif ($c eq 'e') {
            $self->execute_cmd('edit');
          } elsif ($c eq '/') {
            $self->enter_command_mode("search");
          } elsif ($c eq "\n") {
            $self->execute_cmd('open-entry');
          } elsif ($c eq 'q') {
            $self->execute_cmd('quit');
          } elsif ($c eq ':') {
            $self->enter_command_mode;
          }
        } elsif (defined($key)) {
          if ($key == KEY_UP) {
            $self->execute_cmd('go-up');
          } elsif ($key == KEY_DOWN) {
            $self->execute_cmd('go-down');
          } elsif ($key == KEY_HOME) {
            $self->execute_cmd('go-to-first');
          } elsif ($key == KEY_END) {
            $self->execute_cmd('go-to-last');
          } elsif ($key == KEY_ENTER) {
            $self->execute_cmd('open');
          } elsif ($key == KEY_RESIZE) {
            $self->draw;
          }
        }
      } elsif ($self->{mode} eq "command") {
        if (defined($key) && ($key == KEY_BACKSPACE) && (!$self->{cmd_prompt}->{value})) {
          $self->exit_command_mode;
        } elsif (defined($c) && ($c eq "\n")) {
          $self->exit_command_mode;
          $self->execute_cmd($self->{cmd_prompt}->{value});
        } else {
          $self->{cmd_prompt}->key_pressed($c, $key);
        }
      }
    }
  }
}

1;
