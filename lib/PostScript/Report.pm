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
use MooseX::Types::Moose qw(Bool HashRef Int Str);
use PostScript::Report::Types ':all';
use PostScript::File 'pstr';

use PostScript::Report::Font ();

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

sub init
{
  my ($self) = @_;

  foreach my $sectionName (qw(report_header page_header detail
                              page_footer report_footer)) {
    my $section = $self->$sectionName;
    $section->init($self, $self) if $section;
  } # end foreach $sectionName
} # end init

#---------------------------------------------------------------------

sub width  { shift->ps->get_width  }
sub height { shift->ps->get_height }

has row_height => (
  is        => 'ro',
  isa       => Int,
);

has align => (
  is       => 'ro',
  isa      => HAlign,
  default  => 'left',
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

#---------------------------------------------------------------------
has ps => (
  is      => 'ro',
  isa     => 'PostScript::File',
  builder => '_build_ps',
  lazy    => 1,
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
  );
} # end get_font

# This is only for use by PostScript::Report::Font:
sub _get_metrics
{
  my ($self, $name) = @_;

  $self->_font_metrics->{$name} ||= Font::AFM->new($name);
} # end _get_metrics

#---------------------------------------------------------------------
sub generate
{
  my ($self, $data) = @_;

  $self->_data($data);

  my @bb = $self->ps->get_bounding_box;

  $self->page_header->draw(@bb[0,3], $self); # FIXME

  $self->_clear_data;
} # end generate

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
