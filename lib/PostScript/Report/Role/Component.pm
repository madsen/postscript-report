#---------------------------------------------------------------------
package PostScript::Report::Role::Component;
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
# ABSTRACT: Something that can be drawn
#---------------------------------------------------------------------

our $VERSION = '0.04';

use Moose::Role;
use MooseX::AttributeTree ();
use MooseX::Types::Moose qw(Bool Int Num Str);
use PostScript::Report::Types ':all';

my @inherited = (traits => [qw/TreeInherit/]);

=attr-internal parent

This attribute contains a reference to the Container or Report that is
the direct parent of this Component.  It is used for inheritance of
attribute values.  It is filled in by the L</init> method, and you
will probably never deal with it directly.

=cut

has parent => (
  is       => 'ro',
  isa      => Parent,
  weak_ref => 1,
  writer   => '_set_parent',
);

=attr height

This is the height of the component.

=cut

has height => (
  is        => 'ro',
  isa       => Int,
  writer    => '_set_height',
  predicate => 'has_height',
  @inherited,
);

=attr width

This is the width of the component.  In most cases, you will need to
set this explicitly.

=cut

has width => (
  is        => 'ro',
  isa       => Int,
  writer    => '_set_width',
  predicate => 'has_width',
  @inherited,
);

=attr align

This controls text alignment.  It may be C<left>, C<center>, or
C<right>.

=cut

has align => (
  is  => 'ro',
  isa => HAlign,
  @inherited,
);

=attr background

This is the background color for the Component.  The color is a number
in the range 0 to 1 (where 0 is black and 1 is white) for a grey
background, or an arrayref of three numbers C<[ Red, Green, Blue ]>
where each number is in the range 0 to 1.

In addition, you can specify an RGB color in the HTML hex triplet form
prefixed by C<#> (like C<#FFFF00> or C<#FF0> for yellow).

Unlike the other formatting attributes, its value is not actually
inherited, but since a Container draws the background for all its
Components, the effect is the same.

=cut

has background => (
  is       => 'ro',
  isa      => Color,
  coerce   => 1,
  writer   => '_set_background', # Used by Report::_stripe_detail
);

=attr border

This is the border style.  It may be 1 for a solid border or 0 for no
border.  In addition, you may specify any combination of the letters
T, B, L, and R (meaning top, bottom, left, and right) to have a border
only on the specified side(s).

The thickness of the border is controlled by L</line_width>.

(Note: The string you give will be converted into the canonical
representation, which has the letters upper case and in the order
TBLR.)

=cut

has border => (
  is  => 'ro',
  isa => BorderStyle,
  coerce => 1,
  @inherited,
);

=attr font

This is the font used to draw normal text in the Component.

=cut

has font => (
  is  => 'ro',
  isa => FontObj,
  @inherited,
);

=attr label_font

This is the font used to draw the label.  Not all components have a
label.

=cut

has label_font => (
  is  => 'ro',
  isa => FontObj,
  @inherited,
);

=attr line_width

This is the line width.  It's used mainly as the border width.

=cut

has line_width => (
  is  => 'ro',
  isa => Num,
  @inherited,
);

=method draw

  $component->draw($x, $y, $report);

This method draws the component on the current page of the report at
position C<$x>, C<$y>.  This method must be provided by the component.
The Component role provides a C<before draw> modifier to draw the
component's background.

=cut

requires 'draw';

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

=method draw_standard_border

  $component->draw_standard_border($x, $y, $report);

This method draws a border around the component as specified by the
L</border> and L</line_width> attributes.  It can be called by a
component's C<draw> method, or added as an C<after> modifier:

  after draw => \&draw_standard_border;

=cut

sub draw_standard_border
{
  my ($self, $x, $y, $rpt) = @_;

  if ($self->border) {
    $rpt->ps->add_to_page( sprintf(
      "%d %d %d %d %s db%s\n",
      $x, $y, $x + $self->width, $y - $self->height,
      $self->line_width, $self->border
    ));
  }
} # end draw_standard_border

=method id

  $psID = $component->id;

In order to avoid stepping on each other's PostScript code, any
PostScript identifiers created by a component should begin with this
string.  The default implementation returns the last component of the
class name.

=cut

sub id
{
  my $class = blessed shift;
  $class =~ /([^:]+)$/ or confess "No class";

  $1;
} # end id

=method init

  $component->init($parent, $report);

The init method of each component is called at the beginning of each
report run.  The default implementation sets the parent link to enable
inheritance of attribute values.

Most components will need to provide an C<after> modifier to do
additional initialization, such as calculating C<height> or C<width>.
Also, the component should add its standard procedures to
C<< $report->ps_functions >>.

=cut

sub init
{
  my ($self, $parent, $report) = @_;

  $self->_set_parent($parent);
} # end init
#---------------------------------------------------------------------

=method dump

  $component->dump($level);

This method (for debugging purposes only) prints a representation of
the component to the currently selected filehandle.  (Inherited values
are not shown.)  Note that layout calculations are not done until the
report is run, so you will normally see additional C<height> and
C<width> values after calling L</run>.

C<$level> (default 0) indicates the level of indentation to use.

The default implementation should be sufficient for most components.

=cut

sub dump
{
  my ($self, $level) = @_;
  $level ||= 0;

  my $indent = "  " x $level;

  printf "%s%s:\n", $indent, blessed $self;

  my @attrs = sort { $a->name cmp $b->name } $self->meta->get_all_attributes;

  my $is_container;
  ++$level;

  foreach my $attr (@attrs) {
    my $name = $attr->name;

    next if $name eq 'parent';

    if ($name eq 'children' and
        $self->does('PostScript::Report::Role::Component')) {
      $is_container = 1;
    } else {
      PostScript::Report->_dump_attr($self, $attr, $level);
    }
  } # end foreach $attr in @attrs

  return unless $is_container;

  print "$indent  children:\n";

  ++$level;
  foreach my $child (@{ $self->children }) {
    $child->dump($level);
  } # end foreach $child
} # end dump

#=====================================================================
# Package Return Value:

1;

__END__

=head1 DESCRIPTION

This role describes an object that knows how to draw itself on a
report.  A Component that contains other Components is a
L<Container|PostScript::Report::Role::Container>.

=begin Pod::Loom-group_attr *

=head2 Inherited Attributes

These attributes control the component's formatting.  To avoid having
to set all of them on every component, their values are inherited much
like CSS styles are inherited in HTML.  If a component does not have
an explicit value set, then the value is inherited from the parent.
The inheritance may bubble up all the way to the Report object, which
will always provide a default value.

All dimensions are in points.

=begin Pod::Loom-group_attr opt

=head2 Optional Attributes

The following attributes are not present in all components, but when
they are present, they should behave as described here.  Attributes
whose value can be inherited from the parent are marked (Inherited).

=attr-opt padding_bottom

(Inherited) This is the amount of space between the bottom of the
component and the baseline of the text inside it.  If this is too
small, then the descenders (on letters like "p" and "y") will be cut
off.  (The exact minimum necessary depends on the selected font and
size.)

=attr-opt padding_side

(Inherited) This is the amount of space between the side of the
component and the text inside it.

=attr-opt value

This is the C<$value_source> that the component will use to retrieve
its contents.  See L<PostScript::Report/get_value>.

=begin Pod::Loom-group_attr internal

=head2 Internal Attribute

You probably won't need to use this attribute directly.

=head1 SEE ALSO

The following components are available by default:

=over

=item L<Checkbox|PostScript::Report::Checkbox>

This displays a box, which contains a checkmark if the associated
value is true.

=item L<Field|PostScript::Report::Field>

This is a standard text field.

=item L<FieldTL|PostScript::Report::FieldTL>

This is a text field with a label in the corner.  It also (optionally)
supports multiple lines with word wrap.

=item L<HBox|PostScript::Report::HBox>

This Container draws its children in a horizontal row.

=item L<Image|PostScript::Report::Image>

This allows you to include an EPS file.

=item L<Spacer|PostScript::Report::Spacer>

This is just an empty box for padding.

=item L<VBox|PostScript::Report::VBox>

This Container draws its children in a vertical column.

=back

=for Pod::Loom-omit
CONFIGURATION AND ENVIRONMENT

