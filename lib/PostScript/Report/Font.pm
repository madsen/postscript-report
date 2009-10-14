#---------------------------------------------------------------------
package PostScript::Report::Font;
#
# Copyright 2009 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 12 Oct 2009
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Represents a PostScript font
#---------------------------------------------------------------------

our $VERSION = '0.01';

use Moose;
#use Moose::Autobox;
use MooseX::Types::Moose qw(Bool Int Num Str);
use PostScript::Report::Types ':all';

has document => (
  is       => 'ro',
  isa      => Report,
  required => 1,
);

has font => (
  is       => 'ro',
  isa      => Str,
  required => 1,
);

has id => (
  is       => 'ro',
  isa      => Str,
  required => 1,
);

has size => (
  is       => 'ro',
  isa      => Num,
  required => 1,
);

has _metrics => (
  is       => 'ro',
  isa      => FontMetrics,
  lazy     => 1,
  default  => sub { my $self = shift;
                    $self->document->_get_metrics($self->font); },
);

sub width
{
  my $self = shift;

  $self->_metrics->stringwidth(shift, $self->size);
} # end width

sub wrap
{
  my ($self, $width) = @_; # , $text

  my $metrics = $self->_metrics;
  my $size    = $self->size;

  my @lines = '';

  pos($_[2]) = 0;               # Make sure we start at the beginning
  for ($_[2]) {
    if (m/\G[ \t]*\n/gc) {
      push @lines, '';
    } else {
      m/\G(\s*(?:[^-\s]+-*|\S+))/g or last;
      my $word = $1;
    check_word:
      if ($metrics->stringwidth($lines[-1] . $word, $size) <= $width) {
        $lines[-1] .= $word;
      } elsif ($lines[-1] eq '') {
        $lines[-1] = $word;
        warn "$word is too wide for field width $width";
      } else {
        push @lines, '';
        $word =~ s/^\s+//;
        goto check_word;
      }
    } # end else not at LF

    redo;                   # Only the "last" statement above can exit
  } # end for $_[2] (the text to wrap)

  @lines;
} # end wrap

#=====================================================================
no Moose;
__PACKAGE__->meta->make_immutable;
1;
