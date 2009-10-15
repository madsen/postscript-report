#---------------------------------------------------------------------
package PostScript::Report::FieldTL;
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
# ABSTRACT: A field with a label in the top left corner
#---------------------------------------------------------------------

our $VERSION = '0.01';

use Moose;
#use Moose::Autobox;
use MooseX::Types::Moose qw(Bool Int Num Str);
use PostScript::Report::Types ':all';

use PostScript::File 'pstr';

use namespace::autoclean;

with 'PostScript::Report::Role::Component';

my @inherited = (traits => [qw/TreeInherit/]);

has label => (
  is      => 'ro',
  isa     => Str,
  default => '',
);

has value => (
  is       => 'ro',
  isa      => RptValue,
  required => 1,
);

has multiline => (
  is       => 'ro',
  isa      => Bool,
);

has padding_side => (
  is       => 'ro',
  isa      => Num,
  @inherited,
);

sub padding_label_side { shift->padding_side }
sub padding_text_side  { shift->padding_side }
sub padding_label_top { 0 }
sub padding_text_top  { 0 }

after init => sub {
  my ($self, $parent, $report) = @_;

  # Use __PACKAGE__ instead of blessed $self because the string is
  # constant.  Subclasses should either use sub id { 'FieldTL' } or
  # define their own comparable functions:
  $report->ps_functions->{+__PACKAGE__} = <<'END PS';
%---------------------------------------------------------------------
% CONTENT... Csp Cx Cy DISPLAYFUNC LINES CONTENTFONT LABEL Lx Ly L T R B LABELFONT FieldTL
% Leaves on stack: L T R B

/FieldTL
{
  gsave
  setfont
  4 copy clipbox	% C... Csp Cx Cy FUNC LINES CF LABEL Lx Ly L T R B
  3 index		% C... Csp Cx Cy FUNC LINES CF LABEL Lx Ly L T R B L
  7 -1 roll add		% C... Csp Cx Cy FUNC LINES CF LABEL Ly L T R B LblX
  3 index		% C... Csp Cx Cy FUNC LINES CF LABEL Ly L T R B LblX T
  7 -1 roll sub		% C... Csp Cx Cy FUNC LINES CF LABEL L T R B LblX LblY
  7 -1 roll showleft	% C... Csp Cx Cy FUNC LINES CF L T R B
  5 -1 roll setfont	% C... Csp Cx Cy FUNC LINES L T R B
  2 index		% C... Csp Cx Cy FUNC LINES L T R B T
  8 -1 roll sub		% C... Csp Cx FUNC LINES L T R B Ypos
  4 index		% C... Csp Cx FUNC LINES L T R B Ypos L
  3 index		% C... Csp Cx FUNC LINES L T R B Ypos L R
  3 -1 roll		% C... Csp Cx FUNC LINES L T R B L R Ypos
  8 -1 roll		% C... Csp Cx FUNC L T R B L R Ypos LINES
  {			% C... Csp Cx FUNC L T R B L R Ypos
    3 copy		% C... Csp Cx FUNC L T R B L R Ypos L R Ypos
    14 -1 roll		% C... Csp Cx FUNC L T R B L R Ypos L R Ypos CONTENT
    4 2 roll		% C... Csp Cx FUNC L T R B L R Ypos Ypos CONTENT L R
    12 index		% C... Csp Cx FUNC L T R B L R Ypos Ypos CONTENT L R Cx
    12 index cvx exec	% C... Csp Cx FUNC L T R B L R Ypos
    8 index sub		% C... Csp Cx FUNC L T R B L R YposNext
  } repeat
  pop pop pop		% Csp Cx FUNC L T R B
  7 -3 roll		% L T R B Csp Cx FUNC
  pop pop pop		% L T R B
  grestore
} def

%---------------------------------------------------------------------
% Y CONTENT L R Xoff

/FieldTL-C {
  pop                   % Y CONTENT L R
  add 2 div             % Y CONTENT Xpos
  3 1 roll              % Xpos Y CONTENT
  showcenter
} def

%---------------------------------------------------------------------
% Y CONTENT L R Xoff

/FieldTL-L {
  exch pop add		% Y CONTENT Xpos
  3 1 roll              % Xpos Y CONTENT
  showleft
} def

%---------------------------------------------------------------------
% Y CONTENT L R Xoff

/FieldTL-R {
  sub exch pop		% Y CONTENT Xpos
  3 1 roll              % Xpos Y CONTENT
  showright
} def
END PS
};

sub draw
{
  my ($self, $x, $y, $rpt) = @_;

  my @lines = $rpt->get_value($self->value);

  my $FieldTL   = $self->id;
  my $font      = $self->font;
  my $labelSize = $self->label_font->size;

  if ($self->multiline) {
    @lines = $font->wrap($self->width - 1.5 * $self->padding_text_side,
                         @lines);
  } # end if multiline

  $rpt->ps->add_to_page( sprintf(
    "%s %s %s %s /%s-%s %d %s %s %s %s %d %d %d %d %s %s %s db%s\n",
    join(' ', map { pstr($_) } reverse @lines),
    $font->size,
    $self->padding_text_side,
    $font->size + $self->padding_label_top+$labelSize + $self->padding_text_top,
    $FieldTL, uc substr($self->align, 0, 1),
    scalar @lines,
    $font->id,
    pstr($self->label),
    $self->padding_label_side,
    $labelSize + $self->padding_label_top,
    $x, $y, $x + $self->width, $y - $self->height,
    $self->label_font->id,
    $FieldTL,
    $self->line_width, $self->border,
  ));
} # end draw

#=====================================================================
no Moose;
__PACKAGE__->meta->make_immutable;
1;
