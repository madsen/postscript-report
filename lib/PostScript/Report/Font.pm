#---------------------------------------------------------------------
package PostScript::Report::Font;
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
# ABSTRACT: Represents a PostScript font
#---------------------------------------------------------------------

our $VERSION = '0.06';

use Moose;
use MooseX::Types::Moose qw(Bool Int Num Str);
use PostScript::Report::Types ':all';

has document => (
  is       => 'ro',
  isa      => Report,
  weak_ref => 1,
  required => 1,
);

=attr font

This is the PostScript name of the font to use.

=cut

has font => (
  is       => 'ro',
  isa      => Str,
  required => 1,
);

=attr id

This is the PostScript identifier for the scaled font (assigned by the
document).

=cut

has id => (
  is       => 'ro',
  isa      => Str,
  required => 1,
);

=attr size

This is the size of the font in points.

=cut

has size => (
  is       => 'ro',
  isa      => Num,
  required => 1,
);

=attr metrics

This is a L<PostScript::File::Metrics> object providing information
about the dimensions of the font.

=cut

has metrics => (
  is       => 'ro',
  isa      => FontMetrics,
  handles  => [qw(width wrap)],
  lazy     => 1,
  default  => sub {
    my $self = shift;
    $self->document->ps->get_metrics($self->font, $self->size);
  },
);

=method width

  $font->width($text)

This returns the width of C<$text> (in points) if it were printed in
this font.  C<$text> should not contain newlines.

=method wrap

  @lines = $font->wrap($width, $text)

This wraps C<$text> into lines of no more than C<$width> points.  If
C<$text> contains newlines, they will also cause line breaks.

=cut

# width & wrap are now handled by PostScript::File::Metrics

#=====================================================================
no Moose;
__PACKAGE__->meta->make_immutable;
1;

=head1 DESCRIPTION

PostScript::Report::Font represents a font in a L<PostScript::Report>.
You won't deal directly with Font objects unless you are writing your
own L<Components|PostScript::Report::Role::Component>.

You construct a Font object by calling the report's
L<PostScript::Report/get_font> method.
