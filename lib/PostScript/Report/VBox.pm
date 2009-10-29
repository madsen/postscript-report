#---------------------------------------------------------------------
package PostScript::Report::VBox;
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
# ABSTRACT: Hold components in a vertical column
#---------------------------------------------------------------------

our $VERSION = '0.04';

use Moose;
use MooseX::Types::Moose qw(Bool Int Str);
use PostScript::Report::Types ':all';

use namespace::autoclean;

with 'PostScript::Report::Role::Container';

has _saved_height => (
  is        => 'rw',
  isa       => Int,
  clearer   => '_clear_saved_height',
);

around init => sub {
  my $orig = shift;
  my $self = shift;

  $self->$orig(@_);             # Need to set parent first

  $self->_saved_height($self->height) if $self->has_height;
  $self->_set_height($self->row_height);
}; # end around init

after init => sub {
  my ($self, $parent) = @_;

  my $children = $self->children;

  # Set our width to the widest child:
  unless ($self->has_width) {
    my $width;

    foreach my $child (@$children) {
      next unless $child->has_width;
      $width = $child->width if ($child->width > ($width || 0));
    }

    $self->_set_width($width) if defined $width;
  } # end unless we have explicit width

  # Set our height to the sum of the children:
  my $height = $self->_saved_height;
  $self->_clear_saved_height;

  unless (defined $height) {

    if (@$children == 1) {
      $height = $children->[0]->height;
    } else {
      my $row_height = $self->row_height;
      $height = 0;
      foreach my $child (@$children) {
        $child->_set_height($row_height) unless $child->has_height;
        $height += $child->height;
      }
    } # end else not exactly 1 child
  } # end unless we have explicit height

  $self->_set_height($height);

}; # end after init

#---------------------------------------------------------------------
sub draw
{
  my ($self, $x, $y, $rpt) = @_;

  foreach my $child (@{ $self->children }) {
    $child->draw($x, $y, $rpt);

    $y -= $child->height;
  } # end foreach $child
} # end draw

#=====================================================================
no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 DESCRIPTION

This L<Container|PostScript::Report::Role::Container> draws its
children in a vertical column.  There is no space between children.
If the children are of different widths, they are all left aligned.

=head1 ATTRIBUTES

A VBox has all the normal
L<container attributes|PostScript::Report::Role::Container/ATTRIBUTES>.

During layout calculations, a VBox temporarily sets its C<height> to
its C<row_height> (so that its children will inherit that value).
After the children have done their layout calculations, any child
without an explicit height has its height set to the VBox's C<row_height>.

If C<height> is not specified, then the VBox's height is set to the
sum of the heights of the child components.  If the VBox did have an
explicit C<height>, then it is restored after the children have
completed their layout calculations.

If C<width> is not specified, but any child has an explicit width,
then the VBox's width is set to the width of the widest such child.
Otherwise, the width remains unset.

If you specify a height that is more than the sum of the children's
heights, the extra space will appear at the bottom of the box.

If you specify a height that is less than the sum of the children's
heights, the children will overflow the bottom of the box, which
may lead to components printing on top of each other.

=for Pod::Coverage draw

=for Pod::Loom-omit
CONFIGURATION AND ENVIRONMENT
