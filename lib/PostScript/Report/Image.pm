#---------------------------------------------------------------------
package PostScript::Report::Image;
#
# Copyright 2009 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 18 Oct 2009
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Include an EPS file
#---------------------------------------------------------------------

our $VERSION = '0.02';

use Moose;
use MooseX::Types::Moose qw(Bool Int Num Str);
use PostScript::Report::Types ':all';

use File::Spec ();
use List::Util qw(min);

use namespace::autoclean;

with 'PostScript::Report::Role::Component';

my @inherited = (traits => [qw/TreeInherit/]);

=attr file

The name of the file to include.  If you give a relative path, it will
be converted to an absolute path.  Required.

=cut

has file => (
  is       => 'ro',
  isa      => Str,
  required => 1,
  writer   => '_set_file',
);

sub BUILD
{
  my $self = shift;

  # Convert the filename to an absolute path if necessary:
  my $fn = $self->file;

  $self->_set_file( File::Spec->rel2abs($fn) )
      unless File::Spec->file_name_is_absolute($fn);
} # end BUILD

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

=attr scale

This is the factor by which the image will be scaled.  If you supply
an explicit C<height> and/or C<width>, but no C<scale>, then the scale
will be calculated to make the image fit in the specified dimensions
(based on the BoundingBox in the EPS file).  Otherwise, the scale
defaults to 1 (actual size).  Numbers greater than 1 make the image larger.

=cut

has scale => (
  is       => 'ro',
  isa      => Num,
  writer   => '_set_scale',
);

after init => sub {
  my ($self, $parent, $report) = @_;

  unless ($self->has_height and $self->has_width and $self->scale) {
    # Get bounding box from file:
    my $fn = $self->file;
    open(my $in, '<', $fn) or confess "Unable to open $fn: $!";
    defined read($in, my $content, 8192) or confess "Failed to read $fn: $!";

    my ($left, $bottom, $right, $top) = $self->_find_bounding_box(\$content);

    if (not defined $left
        and $content =~ /^\%\%BoundingBox:\s*\(atend\)/m
        and seek($in, 2, -8192)
        and defined read($in, $content, 8192)) {
      ($left, $bottom, $right, $top) = $self->_find_bounding_box(\$content);
    } # end if BoundingBox at end

    close $in;

    if (defined $left) {
      my $imgHeight = ($top - $bottom) || 1;
      my $imgWidth  = ($right - $left) || 1;

      my $scale = $self->scale;

      if ($self->has_height) {
        if ($self->has_width) {
          my $actHeight = $self->height - 2 * $self->padding_bottom;
          my $actWidth  = $self->width  - 2 * $self->padding_side;
          $scale ||= min($actHeight / $imgHeight, $actWidth / $imgWidth);
        } else {
          my $actHeight = $self->height - 2 * $self->padding_bottom;
          $scale ||= $actHeight / $imgHeight;
          $self->_set_width( $imgWidth * $scale + 2 * $self->padding_side );
        } # end else have height but not width
      } elsif ($self->has_width) {
        my $actWidth = $self->width - 2 * $self->padding_side;
        $scale ||= $actWidth / $imgWidth;
        $self->_set_height( $imgHeight * $scale + 2 * $self->padding_bottom );
      } else {
        $scale ||= 1;
        $self->_set_height( $imgHeight * $scale + 2 * $self->padding_bottom );
        $self->_set_width(  $imgWidth  * $scale + 2 * $self->padding_side   );
      }

      $self->_set_scale($scale);
    } # end if bounding box

    $self->_set_scale(1) unless $self->scale;
  } # end unless we have height, width, and scale

  # Use __PACKAGE__ instead of blessed $self because the string is
  # constant.  Subclasses should either use sub id { 'Image' } or
  # define their own comparable functions:
  $report->ps_functions->{+__PACKAGE__} = <<'END PS';
/Image-StartEPSF {
  /Image-PreEPS_state save def
  translate
  dup scale
  /Image-dict_stack countdictstack def
  count /Image-ops_count exch def
  userdict begin
  /showpage {} def
} bind def

/Image-EPSFCleanUp { % clean up after EPSF inclusion
  count Image-ops_count sub {pop} repeat
  countdictstack Image-dict_stack sub {end} repeat
  Image-PreEPS_state restore
} bind def
END PS
}; # end after init

sub draw
{
  my ($self, $x, $y, $rpt) = @_;

  my $content = $rpt->ps->embed_document($self->file);

  my $scale = $self->scale;

  my ($left, $bottom, $right, $top) = $self->_find_bounding_box(\$content);

  if (defined $left) {
    my $actWidth  = ($right - $left) * $scale;

    my $align = $self->align;

    $x += do {
      if    ($align eq 'left')   { $self->padding_side }
      elsif ($align eq 'center') { ($self->width - $actWidth) / 2 }
      else  { $self->width - $self->padding_side - $actWidth }
    };
  } else {
    # Can't find bounding box, so force left alignment:
    $x += $self->padding_side;
    warn "Unable to find BoundingBox for " . $self->file;
  }

  $y += $self->padding_bottom - $self->height;

  $x -= $left   * $scale if $left;
  $y -= $bottom * $scale if $bottom;

  my $Image = $self->id;

  $rpt->ps->add_to_page(
    "$scale $x $y $Image-StartEPSF\n$content$Image-EPSFCleanUp\n"
  );
} # end draw

after draw => \&draw_standard_border;

sub _find_bounding_box
{
  my ($self, $contentRef) = @_;

  $$contentRef =~ /^\%\%BoundingBox:\s*(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/m;
} # end _find_bounding_box

#=====================================================================
no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 DESCRIPTION

This L<Component|PostScript::Report::Role::Component> allows you to
include an EPS file in your report.

=head1 ATTRIBUTES

An Image has all the normal
L<component attributes|PostScript::Report::Role::Component/ATTRIBUTES>,
including C<padding_bottom> and C<padding_side>.

If you specify C<height> but not C<width> (or vice versa), the missing
attribute is calculated based on the image's size, the attribute you
did provide, and the C<scale>.

If you specify neither C<height> nor C<width>, then both are
calculated based on the image size and the C<scale>.

C<align> controls the horizontal alignment of the image.  (Unless it
was unable to find the BoundingBox of the EPS file, in which case left
alignment is forced.)

=for Pod::Coverage BUILD draw

=for Pod::Loom-omit
CONFIGURATION AND ENVIRONMENT

=head1 BUGS AND LIMITATIONS

Since it is non-trivial to turn an EPS file into a PostScript
procedure, the image file is included every time the component is
drawn.  This is no problem when the image appears only once in a
report header or footer, but an image in a page header or footer can
significantly increase the file size.
