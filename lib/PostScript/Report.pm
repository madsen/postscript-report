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

our $VERSION = '0.13';
# This file is part of {{$dist}} {{$dist_version}} ({{$date}})

use 5.008;
use Moose 0.90;                 # Moose::Meta::Attribute::Native
use MooseX::Types::Moose qw(ArrayRef Bool CodeRef HashRef Int Num Str);
use PostScript::Report::Types ':all';
use PostScript::File 2.20 'pstr'; # Use function library

use PostScript::Report::Font ();
use List::Util 'min';
use Scalar::Util 'reftype';

use namespace::autoclean;
#---------------------------------------------------------------------

=method build

  $rpt = PostScript::Report->build(\%description)

This is the usual method for constructing a PostScript::Report.  It
passes the C<%description> to L<PostScript::Report::Builder>.

If C<%description> does not define C<report_class>, then it is set to
the class on which you called C<build>.  (This matters only if you
have subclassed PostScript::Report.)

=cut

sub build
{
  my ($class, $descHash) = @_;

  confess "build is a class method" if ref $class;

  require PostScript::Report::Builder;

  my $builder = PostScript::Report::Builder->new($descHash);

  $builder->report_class($class) unless $descHash->{report_class};

  $builder->build($descHash);
} # end build
#---------------------------------------------------------------------

=for Pod::Loom-sort_attr
report_header
page_header
detail
page_footer
report_footer

=attr-sec report_header

This is printed at the top of the first page.

=attr-sec page_header

This is printed at the top of every page (and below the
C<report_header> on the first page).

=attr-sec detail

This is printed once for each row of C<@rows>.  See L</"run">.

=attr-sec page_footer

This is printed at the end of every page (and above the
C<report_footer> on the last page).  Also see L</"first_footer">
and L</"footer_align">.

=attr-sec report_footer

This is printed at the end of the last page.
Also see L</"first_footer"> and L</"footer_align">.

=cut

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

=attr-fmt detail_background

This is a code reference that is called before the detail section is
drawn.  It receives two parameters: the row number and the row number
on this page (both 0-based).  It returns the background color for the
detail section, or C<undef> (which means to use the same color as last
time).

=cut

has detail_background => (
  is      => 'ro',
  isa     => CodeRef,
);

=attr-fmt first_footer

This may be either C<page> or C<report>, and controls the order of the
footers on the last page.  The default is C<page>, which puts the page
footer above the report footer.

=cut

has first_footer => (
  is      => 'ro',
  isa     => SectionType,
  default => 'page',
);

=attr-fmt footer_align

This may be either C<top>, C<bottom>, or C<split>.  If it's C<bottom>
(the default), the footers are placed at the very bottom of the page,
touching the bottom margin.  If it's C<top>, then the footers are
placed immediately after the last detail row.  If it's C<split>, then
the first footer is placed using C<top>, and the second footer is
placed using C<bottom>.  (Do not use C<split> unless you have defined
both footers.)

=cut

has footer_align => (
  is      => 'ro',
  isa     => FooterPos,
  default => 'bottom',
);

sub _sections { qw(report_header page_header detail page_footer report_footer) }

sub _init
{
  my ($self) = @_;

  $self->_set_ps( my $ps = $self->_build_ps );

  foreach my $sectionName ($self->_sections) {
    my $section = $self->$sectionName or next;
    $section->init($self, $self);
    $section->_set_height($self->row_height) unless $section->has_height;
  } # end foreach $sectionName

  $ps->use_functions(qw(drawBox));

  $self->ps_functions->{+__PACKAGE__} = <<'END PS';
%---------------------------------------------------------------------
% Draw border styles: Left Top Right Bottom Linewidth dbX

/db0 { 5 { pop } repeat } bind def
/db1 { gsave setlinewidth drawBox grestore } bind def

% Easy access to the corners of a box:
% 3 3 1 1
% L T R B

/boxLT { 3 index  3 index } bind def
/boxRT { 1 index  3 index } bind def
/boxLB { 3 index  1 index } bind def
/boxRB { 2 copy           } bind def

% Start drawing a border:  L T R B LW bdrB
/bdrB { gsave setlinewidth } bind def

% Finish drawing a border:  L T R B X Y bdrE
/bdrE {
  lineto stroke			% Finish the line and stroke it
  pop pop pop pop		% Remove L T R B
  grestore
} bind def

/dbT { bdrB  boxLT moveto  boxRT bdrE } bind def
/dbB { bdrB  boxLB moveto  boxRB bdrE } bind def
/dbL { bdrB  boxLT moveto  boxLB bdrE } bind def
/dbR { bdrB  boxRT moveto  boxRB bdrE } bind def

/dbTB { 5 copy  dbT dbB } bind def
/dbLR { 5 copy  dbL dbR } bind def

/dbTL { bdrB  boxRT moveto  boxLT lineto  boxLB bdrE } bind def
/dbTR { bdrB  boxLT moveto  boxRT lineto  boxRB bdrE } bind def
/dbBL { bdrB  boxRB moveto  boxLB lineto  boxLT bdrE } bind def
/dbBR { bdrB  boxLB moveto  boxRB lineto  boxRT bdrE } bind def

/dbTLR { bdrB  boxLB moveto  boxLT lineto  boxRT lineto  boxRB bdrE } bind def
/dbBLR { bdrB  boxLT moveto  boxLB lineto  boxRB lineto  boxRT bdrE } bind def
/dbTBL { bdrB  boxRT moveto  boxLT lineto  boxLB lineto  boxRB bdrE } bind def
/dbTBR { bdrB  boxLT moveto  boxRT lineto  boxRB lineto  boxLB bdrE } bind def

END PS
} # end _init
#---------------------------------------------------------------------
# NOTE: width and height are now handled by the ps attribute:

=method width

  $width = $rpt->width;

This returns the width of the report (the paper width minus the margins).

=method height

  $height = $rpt->height;

This returns the height of the report (the paper height minus the margins).

=attr-in row_height

This is the default height of a row on the report (default 15).

=cut

has row_height => (
  is        => 'ro',
  isa       => Int,
  default   => 15,
);

=attr-in align

This is the default text alignment.  It may be C<left>, C<center>, or
C<right> (default C<left>).

=cut

has align => (
  is       => 'ro',
  isa      => HAlign,
  default  => 'left',
);

=attr-in border

This is the default border style.  It may be 1 for a solid border (the
default), or 0 for no border.  In addition, you may specify any
combination of the letters T, B, L, and R (meaning top, bottom, left,
and right) to have a border only on the specified side(s).

The thickness of the border is controlled by L</line_width>.

(Note: The string you give will be converted into the canonical
representation, which has the letters upper case and in the order
TBLR.)

=cut

has border => (
  is       => 'ro',
  isa      => BorderStyle,
  coerce   => 1,
  default  => 1,
);

=attr-in font

This is the default font.  It defaults to Helvetica 9.

=cut

has font => (
  is       => 'rw',
  isa      => FontObj,
  lazy     => 1,
  default  => sub { shift->get_font(Helvetica => 9) },
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

=attr-in line_width

This is the default line width (0.5 by default).
It's used mainly for component borders.
A line width of 0 means "as thin as possible".

=cut

has line_width => (
  is      => 'ro',
  isa     => Num,
  default => 0.5,
);

=attr-in padding_bottom

This indicates the distance between the bottom of a component and the
baseline of the text inside it (4 by default).  If this is too small,
then the descenders (on letters like "p" and "y") will be cut off.
(The exact minimum necessary depends on the selected font and size.)

=cut

has padding_bottom => (
  is       => 'ro',
  isa      => Num,
  default  => 4,
);

=attr-in padding_side

This indicates the space between the side of a component and the text
inside it (3 by default).

=cut

has padding_side => (
  is       => 'ro',
  isa      => Num,
  default  => 3,
);

=attr-o extra_styles

This is a hash of additional attributes that can be inherited by child
Components.  You wouldn't normally set this directly, because
L<PostScript::Report::Builder> will automatically move any unknown
attributes into this hash.

=cut

has extra_styles => (
  is       => 'ro',
  isa      => HashRef,
);

=method get_style

  $rpt->get_style($attribute)

Child Components call this method to get the inherited value of any
non-standard style attribute.

=cut

sub get_style
{
  my ($self, $attribute) = @_;

  # See if we have the attribute:
  my $styles = $self->extra_styles or return undef;

  return $styles->{$attribute};
} # end get_style

#---------------------------------------------------------------------

=attr-o ps

This is the L<PostScript::File> object containing the report.  It's
constructed by the L</run> method, and can be freed by calling the
L</clear> method.

=method clear

  $rpt->clear()

This releases the PostScript::File object created by running the
report.  You never need to call this method, but it will free up
memory if you want to save the report object and run the report again
later.

=method output

  $rpt->output($filename [, $dir]) # save to file
  $rpt->output()                   # return as string

This method takes the same parameters as L<PostScript::File/output>.
You can pass a filename (and optional directory name) to store the
report in a file.  (No extension will be added to C<$filename>, so it
should normally end in ".ps".)

If you don't pass a filename, then the PostScript code is returned as
a string.

If you want to reuse the report object, you can call C<clear>
afterwards to free up memory.

=cut

has ps => (
  is      => 'ro',
  isa     => 'PostScript::File',
  writer  => '_set_ps',
  clearer => 'clear',
  handles => {
    output => 'output',
    width  => 'get_printable_width',
    height => 'get_printable_height',
  },
  init_arg=> undef,
);

*get__PostScript_File = \&ps;   # Alias for PostScript::Convert

=for Pod::Coverage
get__PostScript_File

=attr-o ps_functions

This is a hashref of PostScript code blocks that should be added to
the L<PostScript::File> object.  The key should begin with the package
inserting the code.  If a package adds more than one such block, the
package name should be followed by a hyphen and the block name.
Blocks are added in ASCIIbetical order.  A component's C<init> method
may add an entry here.

=cut

has ps_functions => (
  is       => 'ro',
  isa      => HashRef[Str],
  default  => sub { {} },
  init_arg => undef,
);

=attr-fmt ps_parameters

This is a hashref of additional parameters to pass to
PostScript::File's constructor.  These values will override the
parameters that PostScript::Report generates itself (but you should
reserve this for things that can't be controlled through
other PostScript::Report attributes).

=cut

has ps_parameters => (
  is       => 'ro',
  isa      => HashRef,
  default  => sub { {} },
);

=attr-fmt paper_size

This the paper size (default C<Letter>).  See L<PostScript::File/paper>.

=cut

has paper_size => (
  is      => 'ro',
  isa     => Str,
  default => 'Letter',
);

=attr-fmt top_margin

This is the top margin (default 72, or one inch).

=attr-fmt bottom_margin

This is the bottom margin (default 72, or one inch).

=attr-fmt left_margin

This is the left margin (default 72, or one inch).

=attr-fmt right_margin

This is the right margin (default 72, or one inch).

=cut

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

=attr-fmt title

This is the report's title, which is used only to set the
corresponding PostScript comment in the document.
The default is C<Report>.

=cut

has title => (
  is      => 'ro',
  isa     => Str,
  default => 'Report',
);

=attr-fmt landscape

If set to a true value, the report will be printed in landscape mode.
The default is false.

=cut

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
    order       => 'Ascend',
    reencode    => 'cp1252',
    file_ext    => '',
    font_suffix => '-iso',
    landscape   => $self->landscape,
    newpage     => 0,
    %{ $self->ps_parameters },
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

=method get_value

  $field_content = $rpt->get_value($value_source)

When a Component needs to fetch the content it should display, it
calls C<get_value> with its RptValue.  This can be one of three
things:

=over

=item a non-negative integer

A 0-based column in the current row (normally used only in the
C<detail> section).  A warning will be issued if the current row does
not have that many columns.

=item a string

An entry in the C<%data> passed to L</run>.  A warning will be issued
if the key does not exist in C<%data>.

=item an object

This returns C<< $value_source->get_value($rpt) >>.

=back

If the result would be C<undef>, the empty string is returned instead.
(No warning is issued for this.)

=cut

sub get_value
{
  my ($self, $value) = @_;

  my $result = do {
    if (ref $value) {
      $value->get_value($self);
    } elsif ($value =~ /^\d+$/) {
      my $row = $self->_rows->[ $self->_current_row ];
      warn sprintf("Row %d has no column %d (only 0 through %d)\n",
                   $self->_current_row, $value, $#$row)
          unless not $row or $value <= $#$row;
      $row->[$value];
    } else {
      my $dataHash = $self->_data;
      warn "$value is not a key in this report's \%data\n"
          unless exists $dataHash->{$value};
      $dataHash->{$value};
    }
  };

  defined($result) ? $result : '';
} # end get_value

#---------------------------------------------------------------------
has _fonts => (
  is       => 'ro',
  isa      => HashRef[FontObj],
  default   => sub { {} },
  init_arg => undef,
);

=method get_font

  $font_object = $rpt->get_font($font_name, $font_size)

Because a report needs to know what fonts will be used in it, you must
use this method to construct L<PostScript::Report::Font> objects.  If
the specified font has already been used in this report, the same
C<$font_object> will be returned.  (Normally, fonts are constructed by
L<PostScript::Report::Builder>.)

=cut

sub get_font
{
  my ($self, $name, $size) = @_;

  unless ($name =~ s/^=//) {
    $name .= '-iso' unless $name eq 'Symbol';
  }

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
#---------------------------------------------------------------------

=attr-o page_count

This contains the number of pages in the report.  It's only valid
after L</run> has been called.

=cut

has page_count => (
  is       => 'ro',
  isa      => Int,
  writer   => '_set_page_count',
  init_arg => undef,
);

=attr-o page_number

This contains the number of the page currently being generated.  It's
only valid while the L</run> method is processing.

=cut

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
  foreach my $sectionName ($self->_sections) {
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
      if $height{report_footer} > $available - $rowsThisPage * $detail -
                                  ($pageCount == 1 ? $height{report_header} : 0);

  $self->_set_page_count($pageCount);
} # end _calculate_page_count
#---------------------------------------------------------------------

=method run

  $rpt->run(\%data, \@rows)

This method runs the report on the specified data.  C<%data> is a hash
containing values for the report.  C<@rows> is an array of arrayrefs
of strings.  The L</detail> section is printed once for each arrayref.

After running the report, you should call L</output> to store the
results.  C<run> returns C<$rpt>, so you can chain the method calls:

  $rpt->run(\%data, \@rows)->output($filename);

If you omit either C<%data> or C<@rows> (or pass C<undef>), an empty
hash or array will be substituted.

=cut

sub run
{
  my ($self, $data, $rows) = @_;

  # Handle $rpt->run(\@rows):
  if (not defined $rows and (reftype($data)||'') eq 'ARRAY') {
    $rows = $data;
    $data = {};
  } # end if only one parameter, and it's an arrayref

  $self->_data($data ||= {});
  $self->_rows($rows ||= []);
  $self->_current_row(0);

  $self->_init;

  $self->_calculate_page_count;

  my $ps = $self->ps;

  my ($x, $yBot, $yTop) = ($ps->get_bounding_box)[0,1,3];

  my $report_header = $self->report_header;
  my $report_footer = $self->report_footer;
  my $page_header   = $self->page_header;
  my $page_footer   = $self->page_footer;
  my $detail        = $self->detail;
  my $footer2bottom = (($self->footer_align eq 'bottom') or
                       ($self->footer_align eq 'split' and
                        $self->first_footer eq 'report'));

  my $minY = $yBot;
  $minY += $detail->height      if $detail;
  $minY += $page_footer->height if $page_footer;

  my $y;
  for my $page (1 .. $self->page_count) {
    $self->_set_page_number($page);
    $ps->newpage($page);

    $y = $yTop;

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
      my $rowOnPage = 0;
      while ($y >= $minY) {
        $self->_stripe_detail($rowOnPage++);
        $detail->draw($x, $y, $self);
        $y -= $detail->height;
        if ($self->_current_row( $self->_current_row + 1 ) > $#$rows) {
          undef $detail;  # There might be another page for the footer
          last;
        } # end if this was the last row
      } # end while room for another row
    } # end if $detail

    # Draw the footer(s):
    if ($report_footer and $page == $self->page_count) {
      # This is the last page, and we have a report_footer:
      my @footers = ($self->first_footer eq 'page'
                     ? ($page_footer, $report_footer)
                     : ($report_footer, $page_footer));
      # Get only defined footers:
      @footers = grep { defined $_ } @footers;

      # Position and draw the first footer:
      if ($self->footer_align eq 'bottom') {
        $y = $yBot;
        $y += $_->height for @footers;
      } # end if footer_align is bottom

      $footers[0]->draw($x, $y, $self);

      # Draw the second footer, if it exists:
      if ($footers[1]) {
        if ($self->footer_align eq 'split') {
          $y = $yBot + $footers[1]->height;
        } else {
          $y -= $footers[0]->height;
        }
        $footers[1]->draw($x, $y, $self);
      } # end if we have a second footer
    } elsif ($page_footer) {
      # This page has only a page_footer:
      $y = $yBot + $page_footer->height if $footer2bottom;
      $page_footer->draw($x, $y, $self);
    } # end elsif $page_footer
  } # end for each $page

  $self->_clear_data;
  $self->_clear_rows;

  $self->_generate_font_list;
  $self->_attach_ps_resources;

  $self;                        # Allow for method chaining
} # end run

#---------------------------------------------------------------------
sub _stripe_detail
{
  my ($self, $rowOnPage) = @_;

  my $code = $self->detail_background or return;

  my $color = $code->($self->_current_row, $rowOnPage);

  $self->detail->_set_background($color) if defined $color;
} # end _stripe_detail

#---------------------------------------------------------------------
sub _generate_font_list
{
  my ($self) = @_;

  my %font;
  my $ps = $self->ps;

  foreach my $font (values %{ $self->_fonts }) {
    my $name = $font->font;
    $font{$font->id} = sprintf("/%s /%s findfont %s scalefont def\n",
                               $font->id, $name, $font->size);

    $name =~ s/-iso$//;
    $ps->need_resource(font => $name);
  } # end foreach $font

  $ps->add_setup(join('',
    "% begin report fonts\n", (sort values %font), "% end report fonts\n"
  ));
} # end _generate_font_list

#---------------------------------------------------------------------
sub _attach_ps_resources
{
  my ($self) = @_;

  my $ps    = $self->ps;
  my $funcs = $self->ps_functions;

  foreach my $key (sort keys %$funcs) {
    # Try to determine the version of this procset:
    my $version;
    $version = do { local $@; eval { $1->VERSION } } if $key =~ /^([\w:]+)/;

    (my $name = $key) =~ s/:/_/g;
    $ps->add_procset($name, $funcs->{$key}, $version);
  } # end foreach $key

  %$funcs = ();                 # Clear out ps_functions
} # end _attach_ps_resources

#=====================================================================
# Debugging support:

=method-dbg dump

  $rpt->dump;

This method (for debugging purposes only) prints a representation of
the report to the currently selected filehandle.  (Inherited values
are not shown.)  Note that layout calculations are not done until the
report is run, so you will normally see additional C<height> and
C<width> values after calling L</run>.

=cut

sub dump
{
  my ($self) = @_;

  my %ignore = map { $_ => 1 } ($self->_sections, qw(
    parent children page_count page_number ps ps_functions title
  ));

  my $i = 0;
  my %order = map { $_ => ++$i } qw(
    paper_size landscape top_margin bottom_margin left_margin right_margin
  );

  my @attrs = sort { ($order{$a->name}||0) <=> ($order{$b->name}||0)
                     or $a->name cmp $b->name }
              grep { not $ignore{$_->name} and not $_->name =~ /^_/ }
              $self->meta->get_all_attributes;

  $self->_dump_attr($self, $_, 0) for @attrs;

  foreach my $sectionName ($self->_sections) {
    my $section = $self->$sectionName or next;

    print "\n$sectionName:\n";
    $section->dump(1);
  } # end foreach $sectionName
} # end dump

#---------------------------------------------------------------------
# This is called by sub-objects to dump an attribute's value:

sub _dump_attr
{
  my ($selfOrClass, $instance, $attr, $level) = @_;

  return unless $attr->has_value($instance);

  my $val = $attr->get_value($instance);
  my $name = $attr->name;
  my $conversion;

  # Dump extra_styles hash:
  if ($name eq 'extra_styles') {
    printf "%s%s:\n", '  ' x $level, $name;
    foreach my $key (sort keys %$val) {
      $conversion = ($key =~ /(?:^|_)color$/ && 'color');
      $selfOrClass->_dump_value($level+1, $key, $val->{$key}, $conversion);
    } # end foreach $key
    return;
  } # end if extra_styles

  # Convert RGB colors from array back to hex triplet:
  if (ref $val and $attr->has_type_constraint and
      $attr->type_constraint->name eq 'PostScript::Report::Types::Color') {
    $conversion = 'color';
  } # end if RGB color

  # Print the attribute and value:
  $selfOrClass->_dump_value($level, $name, $val, $conversion);
} # end _dump_attr

sub _dump_value
{
  my ($selfOrClass, $level, $name, $val, $conversion) = @_;

  if (my $attrClass = blessed $val) {
    if ($attrClass eq 'PostScript::Report::Font') {
      $val = $val->font . ' ' . $val->size;
    } else {
      printf "%s%-14s: %s\n", '  ' x $level, $name, $attrClass;
      $val->dump($level+1);
      return;
    }
  } # end if blessed $val

  if (ref $val) {
    if (not $conversion) {
      my $reftype = reftype($val);

      if ($reftype eq 'HASH') {
        printf "%s%s:\n", '  ' x $level, $name;
        foreach my $key (sort keys %$val) {
          $selfOrClass->_dump_value($level+1, $key, $val->{$key});
        } # end foreach $key
        return;
      } # end if HASH
      elsif ($reftype eq 'ARRAY') {
        printf "%s%s:\n", '  ' x $level, $name;
        my $prefix = ('  ' x $level) . '  - ';
        foreach (@$val) {
          print $prefix . $_ . "\n";
        } # end foreach $key
        return;
      } # end elsif ARRAY
      elsif ($reftype eq 'CODE') {
        $val = 'CODEREF';
      }
    } elsif ($conversion eq 'color') {
      # Convert RGB colors from array back to hex triplet:
      $val = join('', '#', map { sprintf '%02X', 255 * $_ + 0.5 } @$val);
    } # end elsif RGB color
  } # end if value is a reference

  # Print the attribute and value:
  printf "%s%-14s: %s\n", '  ' x $level, $name, $val;
} # end _dump_value

#=====================================================================
# Package Return Value:

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 SYNOPSIS

    use PostScript::Report ();

    my $rpt = PostScript::Report->build(\%report_description);

    # Run the report and save PostScript to a file:
    $rpt->run(\%data, \@rows)->output("filename.ps");

    # Or, if you want PDF output instead of PostScript:
    use PostScript::Convert;
    psconvert($rpt->run(\%data, \@rows), "filename.pdf");

    $rpt->clear;    # If you want to save this object and run it again

=head1 DESCRIPTION

PostScript::Report helps you generate nicely formatted reports using
PostScript.  You do not need any knowledge of PostScript to use this
package (unless you want to create new Component types).

You probably won't create a PostScript::Report object directly using
C<new>.  Instead, you'll pass a report description to the L</"build">
method, which uses L<PostScript::Report::Builder> to construct the
appropriate objects.

All measurements in a report are given in points (PostScript's native
measurement unit).  There are 72 points in one inch
(1 pt is about 0.3528 mm).

If you want to save the report as PDF, you can pass a report object
(after calling C<run>) to L<PostScript::Convert/psconvert>.

=begin Pod::Loom-group_attr sec

=head2 Report Sections

Each section may be any
L<Component|PostScript::Report::Role::Component>, but is usually a
L<Container|PostScript::Report::Role::Container>.  All sections are
optional (but printing a report with no sections will produce a blank
sheet of paper, so you probably want at least one section).

=begin Pod::Loom-group_attr fmt

=head2 Report Formatting

These attributes affect the PostScript::File object, or control the
formatting of the report as a whole.  All dimensions are in points.

=begin Pod::Loom-group_attr in

=head2 Component Formatting

These attributes do not affect the report directly, but are simply
inherited by components that don't have an explicit value for them.
All dimensions are in points.

=begin Pod::Loom-group_attr o

=head2 Other Attributes

You will probably not need to use these attributes unless you are
creating your own components or other advanced tasks.

=for Pod::Loom-sort_method
build
run
output
clear

=begin Pod::Loom-group_method *

=begin Pod::Loom-group_method dbg

=head1 BUGS AND LIMITATIONS

PostScript::Report does not support characters outside of Windows code
page 1252 (aka WinLatin1), which is a superset of the printable
characters in ISO-8859-1 (aka Latin1).  Unfortunately, supporting
Unicode in PostScript is non-trivial.

There is a conflict between versions of MooseX::Types 0.32 and greater
with Moose versions before 2.0800.  PostScript::Report's type library
will trigger that bug.  Either upgrade Moose to 2.0800 or greater, or
downgrade MooseX::Types to 0.31 or below.
