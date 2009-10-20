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

our $VERSION = '0.01';

use Moose;
use MooseX::Types::Moose qw(Bool Int Num Str);
use PostScript::Report::Types ':all';

use File::Spec ();
use List::Util qw(min);

use namespace::autoclean;

with 'PostScript::Report::Role::Component';

my @inherited = (traits => [qw/TreeInherit/]);

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
  /Image-ops_count count 1 sub def
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

=head1 BUGS AND LIMITATIONS

Since it is non-trivial to turn an EPS file into a PostScript
procedure, the image file is included every time the component is
drawn.  This is no problem when the image appears only once in a
report header or footer, but an image in a page header or footer can
significantly increase the file size.
