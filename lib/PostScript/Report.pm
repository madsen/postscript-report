#---------------------------------------------------------------------
package PostScript::Report;
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
# ABSTRACT: Produce formatted reports in PostScript
#---------------------------------------------------------------------

our $VERSION = '0.01';

use 5.008;
use Moose;
use MooseX::Types::Moose qw(ArrayRef Bool HashRef Int Num Str);
use PostScript::Report::Types ':all';
use PostScript::File 'pstr';

use PostScript::Report::Font ();
use List::Util 'min';

use namespace::autoclean;

has report_header => (
  is  => 'rw',
  isa => Component,
);

has page_header => (
  is  => 'rw',
  isa => Component,
);

has detail => (
  is  => 'rw',
  isa => Component,
);

has page_footer => (
  is  => 'rw',
  isa => Component,
);

has report_footer => (
  is  => 'rw',
  isa => Component,
);

sub sections { qw(report_header page_header detail page_footer report_footer) }

sub _init
{
  my ($self) = @_;

  $self->_set_ps( $self->_build_ps );

  foreach my $sectionName ($self->sections) {
    my $section = $self->$sectionName or next;
    $section->init($self, $self);
    $section->_set_height($self->row_height) unless $section->has_height;
  } # end foreach $sectionName

  $self->ps_functions->{+__PACKAGE__} = <<'END PS';
%---------------------------------------------------------------------
% Create a rectangular path:  Left Top Right Bottom boxpath

/boxpath
{
  % stack L T R B
  newpath
  2 copy moveto                 % move to BR
  3 index exch lineto	        % line to BL
  % stack L T R
  1 index
  % stack L T R T
  4 2 roll
  % stack R T L T
  lineto                        % line to TL
  lineto                        % line to TR
  closepath
} bind def

%---------------------------------------------------------------------
% Clip to a rectangle:   Left Top Right Bottom clipbox

/clipbox { boxpath clip } bind def

%---------------------------------------------------------------------
% Draw a rectangle:   Left Top Right Bottom drawbox

/drawbox { boxpath stroke } bind def

%---------------------------------------------------------------------
% Draw border styles: Left Top Right Bottom Linewidth dbX

/db0 { 5 { pop } repeat } bind def
/db1 { gsave setlinewidth drawbox grestore } bind def

%---------------------------------------------------------------------
% Print text centered at a point:  X Y STRING showcenter
%
% Centers text horizontally

/showcenter
{
  newpath
  0 0 moveto
  % stack X Y STRING
  dup 4 1 roll                          % Put a copy of STRING on bottom
  % stack STRING X Y STRING
  false charpath flattenpath pathbbox   % Compute bounding box of STRING
  % stack STRING X Y Lx Ly Ux Uy
  pop exch pop                          % Discard Y values (... Lx Ux)
  add 2 div neg                         % Compute X offset
  % stack STRING X Y Ox
  0                                     % Use 0 for y offset
  newpath
  moveto
  rmoveto
  show
} bind def

%---------------------------------------------------------------------
% Print left justified text:  X Y STRING showleft
%
% Does not adjust vertical placement.

/showleft
{
  newpath
  3 1 roll  % STRING X Y
  moveto
  show
} bind def

%---------------------------------------------------------------------
% Print right justified text:  X Y STRING showright
%
% Does not adjust vertical placement.

/showright
{
  newpath
  0 0 moveto
  % stack X Y STRING
  dup 4 1 roll                          % Put a copy of STRING on bottom
  % stack STRING X Y STRING
  false charpath flattenpath pathbbox   % Compute bounding box of STRING
  % stack STRING X Y Lx Ly Ux Uy
  pop exch pop                          % Discard Y values (... Lx Ux)
  add neg                               % Compute X offset
  % stack STRING X Y Ox
  0                                     % Use 0 for y offset
  newpath
  moveto
  rmoveto
  show
} bind def
END PS
} # end _init

#---------------------------------------------------------------------

sub width  { my @bb = shift->ps->get_bounding_box;  $bb[2] - $bb[0] }
sub height { my @bb = shift->ps->get_bounding_box;  $bb[3] - $bb[1] }

has row_height => (
  is        => 'ro',
  isa       => Int,
  default   => 20,
);

has align => (
  is       => 'ro',
  isa      => HAlign,
  default  => 'left',
);

has border => (
  is       => 'ro',
  isa      => BorderStyle,
  default  => 1,
);

has font => (
  is       => 'rw',
  isa      => FontObj,
  lazy     => 1,
  default  => sub { shift->get_font(Helvetica => 9) },
  init_arg => undef,
);

has label_font => (
  is       => 'rw',
  isa      => FontObj,
  lazy     => 1,
  default  => sub { shift->get_font(Helvetica => 6) },
  init_arg => undef,
);

my $coerce_font = sub {
  my $orig = shift;
  my $self = shift;

  # If they pass a font name & size, create a font object:
  @_ = $self->get_font(@_) if @_ == 2;

  return $self->$orig(@_);
};

around font       => $coerce_font;
around label_font => $coerce_font;

has line_width => (
  is      => 'ro',
  isa     => Num,
  default => 0.5,
);

has padding_bottom => (
  is       => 'ro',
  isa      => Num,
  default  => 2,
);

has padding_side => (
  is       => 'ro',
  isa      => Num,
  default  => 2,
);

#---------------------------------------------------------------------
has ps => (
  is      => 'ro',
  isa     => 'PostScript::File',
  writer  => '_set_ps',
);

has ps_functions => (
  is       => 'ro',
  isa      => HashRef[Str],
  default  => sub { {} },
  init_arg => undef,
);

has paper_size => (
  is      => 'ro',
  isa     => Str,
  default => 'Letter',
);

has top_margin => (
  is      => 'ro',
  isa     => Int,
  default => 72,
);

has bottom_margin => (
  is      => 'ro',
  isa     => Int,
  default => 72,
);

has left_margin => (
  is      => 'ro',
  isa     => Int,
  default => 72,
);

has right_margin => (
  is      => 'ro',
  isa     => Int,
  default => 72,
);

has title => (
  is      => 'ro',
  isa     => Str,
  default => 'Report',
);

has landscape => (
  is      => 'ro',
  isa     => Bool,
  default => 0,
);

sub _build_ps
{
  my ($self) = @_;

  PostScript::File->new(
    paper       => $self->paper_size,
    top         => $self->top_margin,
    bottom      => $self->bottom_margin,
    left        => $self->left_margin,
    right       => $self->right_margin,
    title       => pstr($self->title),
    reencode    => 'ISOLatin1Encoding',
    font_suffix => '-iso',
    landscape   => $self->landscape,
  );
} # end _build_ps

#---------------------------------------------------------------------
has _data => (
  is       => 'rw',
  isa      => HashRef,
  clearer  => '_clear_data',
  init_arg => undef,
);

has _rows => (
  is       => 'rw',
  isa      => ArrayRef[ArrayRef],
  clearer  => '_clear_rows',
  init_arg => undef,
);

has _current_row => (
  is       => 'rw',
  isa      => Int,
  init_arg => undef,
);

sub get_value
{
  my ($self, $value) = @_;

  if (ref $value) {
    $value->get_value($self);
  } elsif ($value =~ /^\d+$/) {
    $self->_rows->[ $self->_current_row ][ $value ];
  } else {
    $self->_data->{$value};
  }
} # end get_value

#---------------------------------------------------------------------
has _fonts => (
  is       => 'ro',
  isa      => HashRef[FontObj],
  default   => sub { {} },
  init_arg => undef,
);

has _font_metrics => (
  is       => 'ro',
  isa      => HashRef[FontMetrics],
  default   => sub { {} },
  init_arg => undef,
);

sub get_font
{
  my ($self, $name, $size) = @_;

  my $fontname = "$name-$size";

  $self->_fonts->{$fontname} ||= PostScript::Report::Font->new(
    document => $self,
    font     => $name,
    size     => $size,
    id       => $self->_next_font_id,
  );
} # end get_font

has _font_id_counter => (
  is       => 'rw',
  isa      => Str,
  init_arg => undef,
  default  => 'A',
);

sub _next_font_id
{
  my ($self) = @_;

  my $id = $self->_font_id_counter;

  my $fontID = "fn$id";

  $self->_font_id_counter(++$id);

  $fontID;
} # end _next_font_id

# This is only for use by PostScript::Report::Font:
sub _get_metrics
{
  my ($self, $name) = @_;

  require Font::AFM;

  $self->_font_metrics->{$name} ||= Font::AFM->new($name);
} # end _get_metrics

#---------------------------------------------------------------------
has page_count => (
  is       => 'ro',
  isa      => Int,
  writer   => '_set_page_count',
  init_arg => undef,
);

has page_number => (
  is       => 'ro',
  isa      => Int,
  writer   => '_set_page_number',
  init_arg => undef,
);

sub _calculate_page_count
{
  my ($self) = @_;

  my $pageHeight = $self->height;
  my $rowCount   = @{ $self->_rows };

  # Collect height of each section:
  my %height;
  foreach my $sectionName ($self->sections) {
    if (my $section = $self->$sectionName) {
      $height{$sectionName} = $section->height;
    } else {
      $height{$sectionName} = 0;
    }
  } # end foreach $sectionName

  # Perform sanity checks:
  if ($height{report_header} + $height{page_header} + $height{detail}
      + $height{page_footer} > $pageHeight) {
    die "Can't fit report header, page header, page footer, and a detail line on a single page";
  }

  if ($height{page_header} + $height{detail} + $height{page_footer}
      + $height{report_footer} > $pageHeight) {
    die "Can't fit page header, page footer, report footer, and a detail line on a single page";
  }

  # Calculate how many lines we can fit on each page:
  my $available = $pageHeight - $height{page_header} - $height{page_footer};
  my $detail    = $height{detail};
  my $pageCount = 1;
  my $rowsThisPage = 0;

  if ($detail) {
    my $rowsPerPage = int($available / $detail);

    $rowsThisPage = min($rowCount,
                        int(($available - $height{report_header}) / $detail));

    while ($rowCount > $rowsThisPage) {
      ++$pageCount;
      $rowCount -= $rowsThisPage;
      $rowsThisPage = min($rowCount, $rowsPerPage);
    } # end while $rowCount > $rowsThisPage
  } # end if detail section

  # If the report_footer won't fit on the last page, add another page:
  ++$pageCount
      if $height{report_footer} > $available - $rowsThisPage * $detail;

  $self->_set_page_count($pageCount);
} # end _calculate_page_count

#---------------------------------------------------------------------
has _generated => (
  is       => 'rw',
  isa      => Bool,
  init_arg => undef,
);

sub generate
{
  my ($self, $data, $rows) = @_;

  $self->_data($data);
  $self->_rows($rows);
  $self->_current_row(0);

  $self->_init;

  $self->_calculate_page_count;

  my $ps = $self->ps;

  my ($x, $yBot, $yTop) = ($ps->get_bounding_box)[0,1,3];

  my $report_header = $self->report_header;
  my $page_header   = $self->page_header;
  my $page_footer   = $self->page_footer;
  my $detail        = $self->detail;

  my $minY = $yBot;
  $minY += $detail->height      if $detail;
  $minY += $page_footer->height if $page_footer;

  for my $page (1 .. $self->page_count) {
    $self->_set_page_number($page);
    $ps->newpage($page) if $page > 1;

    my $y = $yTop;

    if ($report_header) {
      $report_header->draw($x, $y, $self);
      $y -= $report_header->height;
      undef $report_header;     # Only on first page
    } # end if $report_header

    if ($page_header) {
      $page_header->draw($x, $y, $self);
      $y -= $page_header->height;
    } # end if $page_header

    if ($detail) {
      while ($y >= $minY) {
        $detail->draw($x, $y, $self);
        $y -= $detail->height;
        if ($self->_current_row( $self->_current_row + 1 ) > $#$rows) {
          undef $detail;  # There might be another page for the footer
          last;
        } # end if this was the last row
      } # end while room for another row
    } # end if $detail

    if ($page_footer) {
      $page_footer->draw($x, $y, $self);
      $y -= $page_footer->height;
    } # end if $page_header

    if ($page == $self->page_count and $self->report_footer) {
      $self->report_footer->draw($x, $y, $self);
    }
  } # end for each $page

  $self->_clear_data;
  $self->_clear_rows;

  $self->_generate_font_list;
  $self->_attach_ps_resources;

  $self->_generated(1);
} # end generate

#---------------------------------------------------------------------
sub _generate_font_list
{
  my ($self) = @_;

  my %font;

  foreach my $font (values %{ $self->_fonts }) {
    $font{$font->id} = sprintf("/%s /%s-iso findfont %s scalefont def\n",
                               $font->id, $font->font, $font->size);
  } # end foreach $font

  $self->ps_functions->{__PACKAGE__.'-fonts'} = join('', sort values %font);
} # end _generate_font_list

#---------------------------------------------------------------------
sub _attach_ps_resources
{
  my ($self) = @_;

  my $ps    = $self->ps;
  my $funcs = $self->ps_functions;

  foreach my $key (sort keys %$funcs) {
    (my $name = $key) =~ s/:/_/g;
    $ps->add_function($name, $funcs->{$key});
  } # end foreach $key
} # end _attach_ps_resources

#=====================================================================
# Package Return Value:

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 SYNOPSIS

    use PostScript::Report;

=for author to fill in:
    Brief code example(s) here showing commonest usage(s).
    This section will be as far as many users bother reading
    so make it as educational and exeplary as possible.


=head1 DESCRIPTION

=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.
