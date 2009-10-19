#---------------------------------------------------------------------
package PostScript::Report::HBox;
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
# ABSTRACT: Hold components in a horizontal row
#---------------------------------------------------------------------

our $VERSION = '0.01';

use Moose;
use MooseX::Types::Moose qw(Bool Int Str);
use PostScript::Report::Types ':all';

use namespace::autoclean;

with 'PostScript::Report::Role::Container';

after init => sub {
  my $self = shift;

  my $children = $self->children;

  # Set our height to the tallest child:
  unless ($self->has_height) {
    my $height;

    foreach my $child (@$children) {
      next unless $child->has_height;
      $height = $child->height if ($child->height > ($height || 0));
    }

    $self->_set_height($height) if defined $height;
  } # end unless we have explicit height

  # Set our width to the sum of the children:
  unless ($self->has_width) {
    my $width = 0;

    return if @$children == 1;

    foreach my $child (@$children) {
      die "Children of HBox must have explicit width" unless $child->has_width;
      $width += $child->width;
    }

    $self->_set_width($width);
  } # end unless we have explicit width
}; # end after init

#---------------------------------------------------------------------
sub draw
{
  my ($self, $x, $y, $rpt) = @_;

  foreach my $child (@{ $self->children }) {
    $child->draw($x, $y, $rpt);

    $x += $child->width;
  } # end foreach $child
} # end draw

#=====================================================================
no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 DESCRIPTION

This L<Container|PostScript::Report::Role::Container> draws its
children in a horizontal row.  There is no space between children.

=head1 ATTRIBUTES

An HBox has all the normal
L<container attributes|PostScript::Report::Role::Container/ATTRIBUTES>.

If C<height> is not specified, but any child has an explicit height,
then the HBox's height is set to the height of the tallest such child.
Otherwise, the height remains unset.

If C<width> is not specified, then it is set to the sum of the widths
of the child components.  Each child must have an explicit width.

If you specify a width that is more than the sum of the children's
widths, the extra space will appear at the right side of the box.

If you specify a width that is less than the sum of the children's
widths, the children will overflow the right side of the box, which
may lead to components printing on top of each other.

=for Pod::Coverage draw

=for Pod::Loom-omit
CONFIGURATION AND ENVIRONMENT
