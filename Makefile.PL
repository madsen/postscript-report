use 5.008;
use strict;
use warnings;

use ExtUtils::MakeMaker 6.30;
use version 0.77;

eval {
  require Moose;
  require MooseX::Types;

  my $Moose   = Moose->VERSION;
  my $MooseXT = MooseX::Types->VERSION;

  if ((version->parse($Moose)   < version->parse('2.0800')) and
      (version->parse($MooseXT) > version->parse('0.31'))) {
    print <<"END ERROR";

ERROR: Found Moose $Moose with MooseX::Types $MooseXT

You cannot use PostScript::Report with MooseX::Types 0.32 or greater
unless your Moose is 2.0800 or greater.  Either upgrade Moose or
downgrade MooseX::Types to 0.31 or below.
END ERROR
    exit 0;
  }
};

my %WriteMakefileArgs = (
  NAME => "PostScript::Report",
  VERSION_FROM => "lib/PostScript/Report.pm",
##{ $plugin->get_default(qw(ABSTRACT AUTHOR EXE_FILES LICENSE)) ##}
##{ $plugin->get_prereqs ##}
  "test" => {
    "TESTS" => "t/*.t"
  }
);

unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
