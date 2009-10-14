#---------------------------------------------------------------------
package PostScript::Report::Field;
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
# ABSTRACT: A simple field with no label
#---------------------------------------------------------------------

our $VERSION = '0.01';

use Moose;
#use Moose::Autobox;
use MooseX::Types::Moose qw(Bool Int Str);
use PostScript::Report::Types ':all';

use PostScript::File 'pstr';

use namespace::autoclean;

with 'PostScript::Report::Role::Component';

has value => (
  is       => 'ro',
  isa      => RptValue,
  required => 1,
);

has padding_bottom => (
  is       => 'ro',
  isa      => Int,
  default  => 2,
);

has padding_side => (
  is       => 'ro',
  isa      => Int,
  default  => 2,
);

after init => sub {
  my ($self, $parent, $report) = @_;

  $report->ps_functions->{+__PACKAGE__} = <<'END PS';
% X Y STRING FONT L T R B Field-X

/Field-C { gsave clipbox setfont showcenter grestore} bind def
/Field-L { gsave clipbox setfont showleft   grestore} bind def
/Field-R { gsave clipbox setfont showright  grestore} bind def
END PS
}; # end after init

sub draw
{
  my ($self, $x, $y, $rpt) = @_;

  my $align = uc substr($self->align, 0, 1);

  my $xOff = do {
    if    ($align eq 'C') { $self->width / 2 }
    elsif ($align eq 'R') { $self->width - $self->padding_side }
    else                  { $self->padding_side }
  };

  $rpt->ps->add_to_page( sprintf(
    "%s %s %s %s %d %d %d %d Field-%s\n",
    $x + $xOff, $y - $self->height + $self->padding_bottom,
    pstr( $rpt->get_value($self->value) ),
    $self->font->id,
    $x, $y, $x + $self->width, $y - $self->height,
    $align
  ));
} # end draw

after draw => \&draw_standard_border;

#=====================================================================
no Moose;
__PACKAGE__->meta->make_immutable;
1;
