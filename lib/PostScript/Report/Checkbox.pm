#---------------------------------------------------------------------
package PostScript::Report::Checkbox;
#
# Copyright 2009 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 15 Oct 2009
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: A checkbox with no label
#---------------------------------------------------------------------

our $VERSION = '0.01';

use Moose;
#use Moose::Autobox;
use MooseX::Types::Moose qw(Bool Int Num Str);
use PostScript::Report::Types ':all';

use namespace::autoclean;

with 'PostScript::Report::Role::Component';

my @inherited = (traits => [qw/TreeInherit/]);

has value => (
  is       => 'ro',
  isa      => RptValue,
  required => 1,
);

has padding_bottom => (
  is       => 'ro',
  isa      => Num,
  @inherited,
);

has padding_side => (
  is       => 'ro',
  isa      => Num,
  @inherited,
);

=attr size

This is the size of the checkbox (in points).  The default is the
C<height> minus twice the C<padding_bottom>.

=cut

has size => (
  is       => 'ro',
  isa      => Int,
  builder  => '_build_size',
  lazy     => 1,
);

sub _build_size
{
  my ($self) = @_;

  $self->height - 2 * $self->padding_bottom;
} # end _build_size


after init => sub {
  my ($self, $parent, $report) = @_;

  # Set the width based on the checkbox size (if it wasn't set already):
  $self->width( $self->size + 2 * $self->padding_side )
      unless $self->has_width;

  # Use __PACKAGE__ instead of blessed $self because the string is
  # constant.  Subclasses should either use sub id { 'Checkbox' } or
  # define their own comparable functions:
  $report->ps_functions->{+__PACKAGE__} = <<'END PS';
%---------------------------------------------------------------------
% SIZE VALUE X Y LINEWIDTH Checkbox

/Checkbox
{
  gsave
  setlinewidth
  translate			% SIZE VALUE
  0  2 index			% SIZE VALUE L T
  dup  0			% SIZE VALUE L T R B
  drawbox			% SIZE VALUE
  {				% SIZE
    600 div  dup  scale		% stack empty
    newpath
    75 257 moveto
    219 90 lineto
    292 240 382 377 526 508 curveto
    418 447 299 331 197 188 curveto
    closepath
    fill
  }
  { pop } ifelse
  grestore
} bind def
END PS
}; # end after init

sub draw
{
  my ($self, $x, $y, $rpt) = @_;

  my $align = uc substr($self->align, 0, 1);

  my $size = $self->size;

  my $xOff = do {
    if    ($align eq 'C') { ($self->width - $size) / 2 }
    elsif ($align eq 'R') { $self->width - $self->padding_side - $size }
    else                  { $self->padding_side }
  };

  $rpt->ps->add_to_page( sprintf(
    "%s %s %d %d %s %s\n",
    $size,
    ($rpt->get_value($self->value) ? 'true' : 'false'),
    $x + $xOff, $y - $self->height + $self->padding_bottom,
    $self->line_width,
    $self->id,
  ));
} # end draw

after draw => \&draw_standard_border;

#=====================================================================
no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 DESCRIPTION

This L<Component|PostScript::Report::Role::Component> is a checkbox
that may be checked or unchecked.

If the value it retrieves is considered true by Perl, then the box
will be checked.

=head1 ATTRIBUTES

A Field has all the normal
L<component attributes|PostScript::Report::Role::Component/ATTRIBUTES>,
including C<padding_bottom>, C<padding_side>, and C<value>.

The C<align>, C<padding_bottom>, and C<padding_side> attributes act on
the checkbox as if it were text.

=for Pod::Coverage draw

=for Pod::Loom-omit
CONFIGURATION AND ENVIRONMENT
