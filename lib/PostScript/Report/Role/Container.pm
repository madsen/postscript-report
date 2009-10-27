#---------------------------------------------------------------------
package PostScript::Report::Role::Container;
#
# Copyright 2009 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: October 12, 2009
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: A component that has components
#---------------------------------------------------------------------

our $VERSION = '0.03';

use Moose::Role;
use MooseX::AttributeHelpers;
use MooseX::Types::Moose qw(ArrayRef Bool Int Num Str);
use PostScript::Report::Types ':all';

with 'PostScript::Report::Role::Component';

my @inherited = (traits => [qw/TreeInherit/]);

=attr-std background

This is the background color for the Container.  Unlike the other
formatting attributes, it is not inherited.  (Since the Container
draws the background for all its Components, they don't need to
inherit the value.)

The color is a number in the range 0 to 1 (where 0 is black and 1 is
white) for a grey background, or an arrayref of three numbers C<[ Red,
Green, Blue ]> where each number is in the range 0 to 1.

In addition, you can specify an RGB color in the HTML hex triplet form
prefixed by C<#> (like C<#FFFF00> or C<#FF0> for yellow).

=cut

has background => (
  is       => 'ro',
  isa      => Color,
  coerce   => 1,
  writer   => '_set_background', # Used by Report::_stripe_detail
);

=attr-std children

This is an arrayref containing the child Components.

=cut

has children => (
  metaclass => 'Collection::Array',
  is        => 'ro',
  isa       => ArrayRef[Component],
  default   => sub { [] },
  provides  => {
    push => 'add_child',
  },
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

=attr-std row_height

(Inherited) This is used by VBoxes to set the height of children that
don't specify their own height.  L<PostScript::Report::VBox>.

=cut

has row_height => (
  is        => 'ro',
  isa       => Int,
  @inherited,
);

=method draw

The Container role provides a C<before draw> modifier to draw the
container's background, and an C<after draw> modifier to draw a border
around the container.  The container must still provide its own
C<draw> method.

=cut

before draw => sub {
  my ($self, $x, $y, $rpt) = @_;

  if (defined(my $background = $self->background)) {
    $rpt->ps->add_to_page( sprintf(
      "%d %d %d %d %s fillbox\n",
      $x, $y, $x + $self->width, $y - $self->height,
      PostScript::File::str($background)
    ));
  }
}; # end before draw

after draw => \&draw_standard_border;

=method init

The Container role provides an C<after init> modifier that calls
C<init> on each child Component.

=cut

after init => sub {
  my ($self, $parent, $report) = @_;

  $_->init($self, $report) for @{ $self->children };
}; # end after init

#=====================================================================
# Package Return Value:

1;

__END__

=head1 DESCRIPTION

This role describes a L<Component|PostScript::Report::Role::Component>
that contains other Components.

=begin Pod::Loom-group_attr std

In addition to the
L<standard attributes|PostScript::Report::Role::Component/ATTRIBUTES>,
a Container provides the following:

=head2 Inherited Attributes

These attributes are provided so that child components can inherit
them.  They have no effect on the container itself.
L<PostScript::Report::Role::Component/"Optional Attributes">.

=over

=item padding_bottom

=item padding_side

=back

=head2 Other Attributes

=for Pod::Loom-omit
CONFIGURATION AND ENVIRONMENT
