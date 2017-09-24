package MainScreen;

use Curses;
use FindBin qw($Bin);
use lib "$Bin/.";
use Bibman::Bibliography;
use Bibman::EditScreen;
use Bibman::TabularList;
use Bibman::StatusBar;

sub new {
  $class = shift;
  $self = {
    list   => new TabularList(4),
    status => new StatusBar()
  };
  bless $self, $class;
}

sub draw {
  my $self = shift;
  $self->{win}->erase;
  my ($maxy, $maxx);
  $self->{win}->getmaxyx($maxy, $maxx);
  $self->{list}->draw($self->{win}, 0, 0, $maxx, $maxy-3);
  $self->{status}->draw($self->{win}, $maxy-2);
}

sub add_entry {
  my $self = shift;
  my $type = shift;

  my $edit = new EditScreen($type, {});
  my $properties = $edit->show($self->{win});
  $self->draw;
}

sub edit_entry {
  my $self = shift;
  my $key = ${${$self->{list}->{items}}[$self->{list}->{highlight}]}[0];
  my $type = $self->{bibliography}->get_type($key);
  my $properties = $self->{bibliography}->get_properties($key);
  my $edit = new EditScreen($type, $properties);
  my $properties = $edit->show($self->{win});
  $self->draw;
}

sub open_bibliography {
  my $self = shift;
  my $filename = shift;

  $self->{list}->delete_all_items;

  $self->{bibliography} = new Bibliography();
  $self->{bibliography}->read($filename);

  for my $entry (@{$self->{bibliography}->{entries}}) {
    my @list_entry = ();
    if ($entry->key) { push @list_entry, $entry->key; } else { push @list_entry, "unknown"; }
    my $authors = Bibliography::format_authors($entry);
    if ($authors) { push @list_entry, $authors; } else { push @list_entry, "unknown"; }
    my $year = $entry->get('year');
    if ($year) { push @list_entry, $year; } else { push @list_entry, ""; }
    my $title = $entry->get('title');
    if ($title) { push @list_entry, $title; } else { push @list_entry, "unknown"; }
    $self->{list}->add_item(\@list_entry);
  }

  $num_entries = $#{$self->{bibliography}->{entries}}+1;
  $self->{status}->set("Loaded $num_entries entries.");
}

sub prompt_for_command {
}
#   my $self = shift;
#   my $prefix = shift;
# 
#   my ($maxy, $maxx);
#   $self->{win}->getmaxyx($maxy, $maxx);
#   $self->{win}->addstring($maxy-1, 0, ":$prefix");
#   echo();
#   curs_set(1);
# #   $cmd = $self->{win}->getstring();
#   my $position = length $prefix + 1;
#   while (1) {
#     my ($c, $key) = $self->{win}->getchar();
#     if (defined($c)) {
#       if ($c eq "\n") {
#         break;
#       } else {
#       }
#     } elsif (defined($key)) {
#       if ($key == KEY_LEFT) {
#         $position--;
#       } elsif ($key == KEY_RIGHT) {
#         $position++;
#       }
#     }
#   }
#   noecho();
#   curs_set(0);
#   $self->{win}->move($maxy-1, 0);
#   $self->{win}->clrtoeol;
#   return $prefix . $cmd;
# }

sub execute_cmd {
  my $self = shift;
  my $cmdline = shift;

  my @args = split /\s+/, $cmdline;
  my $cmd = shift @args;

  if    ($cmd eq 'add')          { return $self->add_entry(@args);         }
  elsif ($cmd eq 'edit')         { return $self->edit_entry;               }
  elsif ($cmd eq 'go-up')        { return $self->{list}->go_up;            }
  elsif ($cmd eq 'go-to-first')  { return $self->{list}->go_to_first;      }
  elsif ($cmd eq 'go-down')      { return $self->{list}->go_down;          }
  elsif ($cmd eq 'go-to-last')   { return $self->{list}->go_to_last;       }
  elsif ($cmd eq 'open-entry')   { return "open";                          }
  elsif ($cmd eq 'search')       { return $self->{list}->search(@args);    }
  elsif ($cmd eq 'search-next')  { return $self->{list}->search_next;      }
  else {
  }
}

sub show {
  my $self = shift;
  my $win = shift;

  $self->{win} = $win;
  $self->draw;

  while (1) {
    my ($c, $key) = $win->getchar();
    my $cmd = '';
    if (defined($c)) {
      if ($c eq 'k') {
        $cmd = 'go-up';
      } elsif ($c eq 'j') {
        $cmd = 'go-down';
      } elsif ($c eq 'g') {
        $cmd = 'go-to-first';
      } elsif ($c eq 'G') {
        $cmd = 'go-to-last';
      } elsif ($c eq 'n') {
        $cmd = 'search-next';
      } elsif ($c eq 'a') {
        $cmd = $self->prompt_for_command("add");
      } elsif ($c eq 'e') {
        $cmd = 'edit';
      } elsif ($c eq '/') {
        $cmd = $self->prompt_for_command("search");
      } elsif ($c eq "\n") {
        $cmd = 'open-entry';
      } elsif ($c eq 'q') {
        $cmd = 'quit';
      } elsif ($c eq ':') {
        $cmd = $self->prompt_for_command();
      }
    } elsif (defined($key)) {
      if ($key == KEY_UP) {
        $cmd = 'go-up';
      } elsif ($key == KEY_DOWN) {
        $cmd = 'go-down';
      } elsif ($key == KEY_HOME) {
        $cmd = 'go-to-first';
      } elsif ($key == KEY_END) {
        $cmd = 'go-to-last';
      } elsif ($key == KEY_ENTER) {
        $cmd = 'open';
      } elsif ($key == KEY_RESIZE) {
        $self->draw;
      }
    }
    if ($cmd eq 'quit') {
      return;
    } else {
      $self->execute_cmd($cmd);
    }
  }
}

1;
