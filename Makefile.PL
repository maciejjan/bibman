use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'Bibman',
  VERSION       => '0.4-alpha',
  EXE_FILES     => ["bin/bibman"],
  PREREQ_PM     => {
    "Curses"           => 0,
    "Env"              => 0,
    "File::Basename"   => 0,
    "List::Util"       => 0,
    "Pod::Usage"       => 0,
    "Text::BibTeX"     => 0,
    "Try::Tiny"        => 0,
  }
);
