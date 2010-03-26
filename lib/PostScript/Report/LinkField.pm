#---------------------------------------------------------------------
package PostScript::Report::LinkField;
#
# Copyright 2010 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 24 Mar 2010
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: A field that can contain hyperlinks
#---------------------------------------------------------------------

our $VERSION = '0.06';

use Moose;
use MooseX::Types::Moose qw(Bool Int Num Str);
use PostScript::Report::Types ':all';

use namespace::autoclean;
#use Smart::Comments '###';

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

=attr link_color

This is the color used by hyperlinks (default C<#00F>, meaning blue).
See L<PostScript::Report::Types/Color>.

=cut

has link_color => (
  is       => 'ro',
  isa      => Color,
  coerce   => 1,
  default  => sub { [ 0, 0, 1 ] }, # Blue
);

=attr text_color

This is the color used by regular text (default 0, meaning black).

=cut

has text_color => (
  is       => 'ro',
  isa      => Color,
  coerce   => 1,
  default  => 0, # Black
);

=attr underline

If set to a true value, hyperlinks will be underlined.
The default is true.

=cut

has underline => (
  is       => 'ro',
  isa      => Bool,
  default  => 1,
);

after init => sub {
  my ($self, $parent, $report) = @_;

  # Use __PACKAGE__ instead of blessed $self because the string is
  # constant.  Subclasses should either use sub id { 'LinkField' } or
  # define their own comparable functions:
  $report->ps_functions->{+__PACKAGE__} = <<'END PS';
%---------------------------------------------------------------------
% PROC X Y FONT L T R B LinkField

/LinkField {
  gsave clipbox setfont translate 0 0 moveto exec grestore
} bind def

% STRING Yoff LinkField-UL
/LinkField-UL {
  currentpoint   4 -1 roll  show
  currentpoint      % Yoff XL YL XR YR
  5 1 roll          % YR Yoff XL YL XR
  dup  3 index  sub % YR Yoff XL YL XR Width
  0 0  7 -3 roll    % YR XR Width 0 0 Yoff XL YL
  newpath
  moveto rmoveto rlineto stroke % YR XR
  newpath
  exch moveto
} bind def

% Define pdfmark for interpreters that don't have it:
/pdfmark where
{ pop }
{ /globaldict where { pop globaldict } { userdict } ifelse
  /pdfmark /cleartomark load put
}
ifelse
END PS
}; # end after init

after draw => \&draw_standard_border;

sub draw
{
  my ($self, $x, $y, $rpt) = @_;

  my $ps    = $rpt->ps;
  my $value = $self->parse_value( $rpt->get_value($self->value) );
  my $font  = $self->font;

  my $link_color = PostScript::File::str($self->link_color);
  my $text_color = PostScript::File::str($self->text_color);
  my $width = 0;
  my $code  = '';
  my @marks;

  # Decide if we're going to underline:
  my $show = 'show';

  if ($self->underline) {
    $code .= sprintf "%s setlinewidth\n", $font->metrics->underline_thickness;
    $show =  sprintf "%s %s-UL", $font->metrics->underline_position, $self->id;
  }

  # Draw the text:
  foreach my $entry (@$value) {
    if (ref $entry) {
      # Hyperlink:
      my %mark = ( left => $width, url => $entry->{url} );
      my $text = $entry->{text};
      $mark{right} = $width += $font->width($text);
      $code .= sprintf("%s setColor\n%s\n%s\n", $link_color, $ps->pstr($text),
                       $show);
      push @marks, \%mark;
    } else {
      # Plain text:
      $width += $font->width($entry);
      $code .= sprintf "%s setColor\n%s\nshow\n", $text_color, $ps->pstr($entry);
    }
  } # end foreach $entry

  # Place the hyperlinks:
  my $top    = $font->size;
  my $bottom = $font->metrics->descender;

  foreach my $mark (@marks) {
    $code .= sprintf( "[/Rect %s\n/Action /Launch\n/URI %s\n"
                      . "/Color [0 0 0]\n/Border [0 0 0]\n"
                      . "/Subtype /Link\n/ANN pdfmark\n",
                      PostScript::File::str([ $mark->{left}, $bottom,
                                              $mark->{right}, $top ]),
                      PostScript::File->pstr($mark->{url}));
  }

  # Calculate the starting position:
  my $align = $self->align;

  my $xOff = do {
    if    ($align eq 'center') { ($self->width - $width) / 2 }
    elsif ($align eq 'right')  { $self->width - $self->padding_side - $width }
    else                       { $self->padding_side }
  };

  $ps->add_to_page( sprintf(
    "{\n%s}\n %s %s %s %d %d %d %d %s\n",
    $code,
    $x + $xOff, $y - $self->height + $self->padding_bottom,
    $self->font->id,
    $x, $y, $x + $self->width, $y - $self->height,
    $self->id
  ));
} # end draw

sub parse_value
{
  my $self = shift;

  my @list;

  for (@_) {
    pos $_ = 0;

    while (not /\G\z/gc) {
      if (/\G\[/gc) {
        # Start of link: [text](url)
        my $startPos = pos($_) - 1;
        my $text = '';
        while (not /\G\]/gc) {
          /\G\\(.?)/gc or /\G([^\\\]]+)/gc
              or die "expected closing bracket after " . substr($_, 0, pos $_);
          $text .= $1;
        }
        /\G\(([^)]+)\)/gc
            or die "expected (URL) after " . substr($_, $startPos,
                                                    pos($_) - $startPos);
        push @list, { text => $text, url => $1 };
      } elsif (/\G<([[:alpha:]]+:\S+?)>/gc) {
        # Hyperlink: <http://foo>
        push @list, { text => $1, url => $1 };
      } elsif (/\G<([^\s\[<>]+\@[^\s\[<>]+)>/gc) {
        # Email address: <foo@example.com>
        push @list, { text => $1, url => "mailto:$1" };
      } elsif (/\G\\(.?)/gc or /\G([^\\\[][^\\\[<]*)/gc) {
        # Regular text:
        push @list, '' if not @list or ref $list[-1];
        $list[-1] .= $1;
      } else {
        die "unparsable input $_" # This should be impossible to reach
      }
    } # end while not at end of string
  } # end for value

  ### parsed: @list;

  return \@list;
} # end parse_value

#=====================================================================
no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 DESCRIPTION

This L<Component|PostScript::Report::Role::Component> is a text field
that can contain hyperlinks.  It's intended for use when the report
will be converted to a PDF file.

Note:  While you may use a LinkField as a label by giving it a
L<constant value|PostScript::Report::Value::Constant>, it always uses
C<font> to draw the text, not C<label_font>.

The hyperlink syntax is a tiny subset of Markdown syntax
(L<http://daringfireball.net/projects/markdown/syntax>).  Only the
following codes are recognized:

  [link text](URL)
  <SCHEME:URL>
  <EMAIL@DOMAIN>

The angle bracket forms cannot contain whitespace, or they will not be
recognized.  If you want angle brackets surrounding the link in the
text, use two angle brackets: C<<< <<EMAIL@DOMAIN>> >>>.

You can escape any character by preceding it with a backslash.  The
only characters that I<must> be escaped are C<\> and C<[> (and C<< < >>
if it would otherwise appear to start a hyperlink).

An unescaped C<[> must be the start of a C<[link text](URL)>
form or it will generate an error.

=head1 ATTRIBUTES

A LinkField has all the normal
L<component attributes|PostScript::Report::Role::Component/ATTRIBUTES>,
including C<padding_bottom>, C<padding_side>, and C<value>.

=for Pod::Coverage
draw
parse_value

=for Pod::Loom-omit
CONFIGURATION AND ENVIRONMENT
