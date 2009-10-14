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
use MooseX::Types::Moose qw(Bool Int Str);
use PostScript::Report::Types ':all';

use PostScript::File 'pstr';

use namespace::autoclean;

with 'PostScript::Report::Role::Component';

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

has actual_height => (
  is       => 'ro',
  isa      => Int,
);

has multiline => (
  is       => 'ro',
  isa      => Bool,
);

sub side_padding_label { 3 }
sub side_padding_text  { 3 }
sub top_padding_label { 0 }
sub top_padding_text  { 0 }

after init => sub {
  my ($self, $parent, $report) = @_;

  my $lblSide = $self->side_padding_label;
  my $txtSide = $self->side_padding_text;

  $report->ps_functions->{+__PACKAGE__} = <<"END PS";
%---------------------------------------------------------------------
% LINEWIDTH CONTENT... Csp Cy DISPLAYFUNC LINES CONTENTFONT LABEL Ly L T R B LABELFONT FieldTL

/FieldTL
{
  gsave
  setfont
  4 copy clipbox        % CONTENT... Csp Cy FUNC LINES CF LABEL Ly L T R B
  3 index $lblSide add  % CONTENT... Csp Cy FUNC LINES CF LABEL Ly L T R B LblX
  3 index    		% CONTENT... Csp Cy FUNC LINES CF LABEL Ly L T R B LblX T
  7 -1 roll sub   	% CONTENT... Csp Cy FUNC LINES CF LABEL L T R B LblX LblY
  7 -1 roll showleft 	% CONTENT... Csp Cy FUNC LINES CF L T R B
  5 -1 roll setfont     % CONTENT... Csp Cy FUNC LINES L T R B
  2 index               % CONTENT... Csp Cy FUNC LINES L T R B T
  8 -1 roll sub         % CONTENT... Csp FUNC LINES L T R B Ypos
  4 index               % CONTENT... Csp FUNC LINES L T R B Ypos L
  3 index               % CONTENT... Csp FUNC LINES L T R B Ypos L R
  3 -1 roll             % CONTENT... Csp FUNC LINES L T R B L R Ypos
  8 -1 roll             % CONTENT... Csp FUNC L T R B L R Ypos LINES
  {                     % CONTENT... Csp FUNC L T R B L R Ypos
    3 copy              % CONTENT... Csp FUNC L T R B L R Ypos L R Ypos
    13 -1 roll          % CONTENT... Csp FUNC L T R B L R Ypos L R Ypos CONTENT
    4 2 roll            % CONTENT... Csp FUNC L T R B L R Ypos Ypos CONTENT L R
    11 index cvx exec   % CONTENT... Csp FUNC L T R B L R Ypos
    8 index sub         % CONTENT... Csp FUNC L T R B L R YposNext
  } repeat
  pop pop pop 		% LINEWIDTH Csp FUNC L T R B
  grestore
  gsave
  7 -1 roll setlinewidth % Csp FUNC L T R B
  drawbox                % Csp FUNC
  grestore
  pop pop
} def

%---------------------------------------------------------------------
% Y CONTENT L R

/FieldTL-C {
  add 2 div             % Y CONTENT Xpos
  3 1 roll              % Xpos Y CONTENT
  showcenter
} def

%---------------------------------------------------------------------
% Y CONTENT L R

/FieldTL-L {
  pop                   % Y CONTENT L
  $txtSide add		% Y CONTENT Xpos
  3 1 roll              % Xpos Y CONTENT
  showleft
} def

%---------------------------------------------------------------------
% Y CONTENT L R

/FieldTL-R {
  exch pop              % Y CONTENT R
  $txtSide sub		% Y CONTENT Xpos
  3 1 roll              % Xpos Y CONTENT
  showright
} def
END PS
};

sub draw
{
  my ($self, $x, $y, $rpt) = @_;

  my @lines = $rpt->get_value($self->value);

  my $font      = $self->font;
  my $labelSize = $self->label_font->size;

  if ($self->multiline) {
    @lines = $font->wrap($self->width - 1.5 * $self->side_padding_text,
                         @lines);
  } # end if multiline

  $rpt->ps->add_to_page( sprintf(
    "%s %s %s %s /FieldTL-%s %d %s %s %s %d %d %d %d %s FieldTL\n",
    $self->line_width,
    join(' ', map { pstr($_) } reverse @lines),
    $font->size,
    $font->size + $self->top_padding_label+$labelSize + $self->top_padding_text,
    uc substr($self->align, 0, 1),
    scalar @lines,
    $font->id,
    pstr($self->label),
    $labelSize + $self->top_padding_label,
    $x, $y, $x + $self->width, $y - ($self->actual_height || $self->height),
    $self->label_font->id
  ));
} # end draw

#=====================================================================
no Moose;
__PACKAGE__->meta->make_immutable;
1;
