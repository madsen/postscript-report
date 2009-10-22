#---------------------------------------------------------------------
package PostScript::Report::Builder;
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
# ABSTRACT: Build a PostScript::Report object
#---------------------------------------------------------------------

our $VERSION = '0.02';

use 5.008;
use Moose;
use MooseX::Types::Moose qw(Bool HashRef Int Str);
use PostScript::Report::Types ':all';

use PostScript::Report::HBox ();
use PostScript::Report::VBox ();
use String::RewritePrefix ();

use namespace::autoclean;

our %loaded_class;

=attr default_field_type

This is the default component class used when building the report
sections.  It defaults to L<Field|PostScript::Report::Field>.

You can temporarily override this by specifying the C<_default> key as
a container's parameter.

=cut

has default_field_type => (
  is  => 'ro',
  isa => Str,
  default => 'Field',
);

=attr default_column_header

This is the default component class used for column headers.
It defaults to L<Field|PostScript::Report::Field>.

=cut

has default_column_header => (
  is  => 'ro',
  isa => Str,
  default => 'Field',
);

=attr default_column_type

This is the default component class used for column fields.
It defaults to L<Field|PostScript::Report::Field>.

=cut

has default_column_type => (
  is  => 'ro',
  isa => Str,
  default => 'Field',
);

=attr report_class

This is the class of object that will be constructed.
It defaults to L<PostScript::Report>.
This must always be a full class name.

=cut

has report_class => (
  is      => 'rw',
  isa     => Str,
  default => 'PostScript::Report',
);

has _fonts => (
  is       => 'rw',
  isa      => HashRef[FontObj],
  init_arg => undef,
  clearer  => '_clear_fonts',
);

# These parameters should simply be passed through to the Report constructor:
our @constructor_args = qw(
  align
  border
  bottom_margin
  footer_align
  landscape
  left_margin
  line_width
  padding_bottom
  padding_side
  paper_size
  ps_parameters
  right_margin
  row_height
  title
  top_margin
);
#---------------------------------------------------------------------

=method build

  $rpt = $builder->build(\%report_description)
  $rpt = PostScript::Report::Builder->build(\%report_description)

This can be called as either an object or class method.  When called
as a class method, it constructs a temporary object by passing the
description to C<new>.

=cut

sub build
{
  my ($self, $descHash) = @_;

  my %desc = %$descHash;        # Don't want to change the original

  # If we're called as a package method, construct a temporary object:
  unless (ref $self) {
    $self = $self->new(\%desc);
  }

  # Construct the PostScript::Report object:
  $self->require_class( $self->report_class );

  my $rpt = $self->report_class->new(
    map { exists $desc{$_} ? ($_ => $desc{$_}) : () } @constructor_args
  );

  # Create the fonts we'll be using:
  $self->create_fonts( $rpt, $desc{fonts} );

  # Set the report's default fonts:
  foreach my $type (qw(font label_font)) {
    next unless exists $desc{$type};

    $rpt->$type( $self->get_font( $desc{$type} ) );
  }

  # Prepare the columns:
  $self->create_columns(\%desc) if $desc{columns};

  # Construct the report sections:
  foreach my $sectionName ($rpt->_sections) {
    my $section = $desc{$sectionName} or next;

    $rpt->$sectionName( $self->build_section( $section ));
  } # end foreach $sectionName

  # Clean up and return the report:
  $self->_clear_fonts;

  $rpt;
} # end build

#---------------------------------------------------------------------
sub get_font
{
  my ($self, $fontname) = @_;

  $self->_fonts->{$fontname}
      or die "$fontname was not listed in 'fonts'";
} # end get_font

#---------------------------------------------------------------------
sub create_fonts
{
  my ($self, $rpt, $desc) = @_;

  my %font;

  while (my ($name, $desc) = each %$desc) {
    $desc =~ /^(.+)-(\d+(?:\.\d+)?)/
        or die "Invalid font description $desc for $name";

    $font{$name} = $rpt->get_font($1, $2);
  }

  $self->_fonts(\%font);
} # end create_fonts

#---------------------------------------------------------------------
sub create_columns
{
  my ($self, $desc) = @_;

  confess "Can't use both detail and columns" if $desc->{detail};

  my $columns = $desc->{columns};

  my @header = (HBox => $columns->{header} || {});
  my @detail = (HBox => $columns->{detail} || {});

  my $colNum = 0;
  foreach my $col (@{ $columns->{data} }) {
    my (%headerDef, %detailDef);

    %headerDef = %{ $col->[2] } if $col->[2];
    %detailDef = %{ $col->[3] } if $col->[3];

    $headerDef{width} = $detailDef{width} = $col->[1];

    $headerDef{_class} ||= $self->default_column_header;
    $detailDef{_class} ||= $self->default_column_type;

    $headerDef{value} ||= { qw(_class Constant  value), $col->[0] };
    $detailDef{value} ||= $colNum++;

    push @header, \%headerDef;
    push @detail, \%detailDef;
  } # end foreach $col

  if ($desc->{page_header}) {
    # Can't just push, because we don't want to modify the original:
    $desc->{page_header} = [ @{ $desc->{page_header} }, \@header ];
  } else {
    $desc->{page_header} = \@header;
  }

  $desc->{detail} = \@detail;
} # end create_columns

#---------------------------------------------------------------------
sub build_section
{
  my ($self, $desc) = @_;

  my $type = ref $desc or die "Expected reference";

  # A section could be just a single object:
  return $self->build_object($desc, $self->default_field_type)
      if $type eq 'HASH';

  die "Expected array reference" unless $type eq 'ARRAY';

  # By default, we want a VBox, but if it appears we have just one
  # arrayref, assume we want an HBox:
  my $boxType = ((ref($desc->[0]) || q{}) eq 'HASH'
                 ? 'HBox' : 'VBox');

  # Recursively build the box:
  return $self->build_box($desc, $boxType, $self->default_field_type);
} # end build_section

#---------------------------------------------------------------------
sub build_box
{
  my ($self, $desc, $boxType, $defaultClass) = @_;

  die "Empty box is not allowed" unless @$desc;

  my $start = 0;
  my %param;

  # If [ className => { ... } ], use it:
  if (not ref $desc->[0]) {
    $boxType  = $desc->[0];
    %param = %{ $desc->[1] };
    $defaultClass = delete $param{_default} if exists $param{_default};
    $self->_fixup_parms(\%param);
    $start = 2;
  }

  my @children = map {
    ref $_ eq 'HASH'
        ? $self->build_object($_, $defaultClass)
        : $self->build_box($_, ($boxType eq 'HBox' ? 'VBox' : 'HBox'),
                           $defaultClass)
  } @$desc[$start .. $#$desc];

  # Construct the box:
  $self->get_class($boxType)->new(children => \@children, %param);
} # end build_box

#---------------------------------------------------------------------
sub build_object
{
  my ($self, $desc, $class, $prefix) = @_;

  my %parms = %$desc;

  $class = $self->get_class(delete($parms{_class}) || $class, $prefix);

  $self->_fixup_parms(\%parms);

  $self->require_class($class);
  $class->new(\%parms);
} # end build_object

#---------------------------------------------------------------------
sub get_class
{
  my ($self, $class, $prefix) = @_;

  die "Unable to determine class" unless $class;

  return String::RewritePrefix->rewrite(
    {'=' => q{},  q{} => ($prefix || 'PostScript::Report::')},
    $class
  );
} # end get_class

#---------------------------------------------------------------------
sub _fixup_parms
{
  my ($self, $parms) = @_;

  while (my ($key, $val) = each %$parms) {
    if ($key =~ /(?:^|_)font$/) {
      $parms->{$key} = $self->get_font($val);
    } elsif ($key eq 'value' and ref $val) {
      if (ref $val eq 'SCALAR') {
        $self->require_class('PostScript::Report::Value::Constant');
        $parms->{$key} = PostScript::Report::Value::Constant->new(
          value => $$val
        );
      } else {
        $parms->{$key} = $self->build_object($val, undef,
                                             'PostScript::Report::Value::');
      }
    } # end elsif key 'value' and ref $val
  } # end while each ($key, $val) in %$parms
} # end _fixup_parms

#---------------------------------------------------------------------
sub require_class
{
  my ($self, $class) = @_;

  return if $loaded_class{$class};

  die "Invalid class name $class" unless $class =~ /^[:_A-Z0-9]+$/i;
  eval "require $class;" or die "Unable to load $class: $@";

  $loaded_class{$class} = 1;
} # end require_class

#=====================================================================
# Package Return Value:

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 SYNOPSIS

    use PostScript::Report ();

    my $rpt = PostScript::Report->build(\%report_description);

=head1 DESCRIPTION

Because a PostScript::Report involves constructing a number of related
objects, it's usually more convenient to pass a description of the
report to a builder object.

You can find example reports in the F<examples> directory of this
distribution.

The C<%report_description> is a hash with keys as follows:

=head2 Report Attributes

Any of the Report attributes listed under
L<PostScript::Report/"Report Formatting"> or
L<PostScript::Report/"Component Formatting"> may be
set by the report description.

=head2 Builder Attributes

Any of the attributes listed in L</ATTRIBUTES> may be set by the
report description I<when C<build> is called as a class method>.

=head2 Font Specifications

All fonts used in a report must be defined in a hashref under the
C<fonts> key (unless you only want to use the report's default fonts).
The keys in this hashref are arbitrary strings, and the values are
strings in the form FONTNAME-SIZE.

If you use the same value more than once, then both keys will refer to
the same font object.  This allows you to use the same font for
different purposes, while retaining the ability to substitute a
different font for one of those purposes just by changing the C<fonts>
hash.

When you set a C<font> or C<label_font> attribute, its value must be
one of the keys in the C<fonts> hash.

Example:

  fonts => {
    label    => 'Helvetica-6',
    text     => 'Helvetica-9',
  },

  font       => 'text',
  label_font => 'label',


=head2 Report Sections

Any of the sections listed under L<PostScript::Report/"Report Sections">
may be defined by the report description.
The value is interpreted as follows:

Components are created by hashrefs.  Containers are created by arrayrefs.

If the section is a container, the initial container type is chosen
like this: If the first value in the arrayref is a hashref, you get an
HBox.  Otherwise, you get a VBox.

After that, the box types alternate.  If you place an arrayref in an
HBox, it becomes a VBox.  An arrayref in a VBox becomes an HBox.

You can override the box type (or pass parameters to its constructor),
by making the first entry in the arrayref a string (the container
type) and the second entry a hashref to pass to its constructor.  If
that hashref contains a C<_default> key, its value becomes the default
component class inside this container.

The hashref that represents a Component is simply passed to its
constructor, with one exception.  If the hash contains the C<_class>
key, that value is removed and used as the class name.

=head3 Constant Values

As a special case, you can pass a scalar reference as the C<value> for
a Component.  This creates a
L<constant value|PostScript::Report::Value::Constant>.  That is,

  value => \'Label:',

is equivalent to

  value => { _class => 'Constant',  value => 'Label:' },

=head3 A Note on Class Names

Anywhere you specify a class name, C<PostScript::Report::> is
automatically prepended to the name you give.  To use a class outside
that namespace, prefix the class name with C<=>.

There are two exceptions to this:

=over

=item 1.

When you give a hashref as the value of a C<value> attribute, the
prefix is C<PostScript::Report::Value::> instead of just
C<PostScript::Report::>.

=item 2.

The C<report_class> is always a complete class name.

=back

=head2 Report Columns

The C<columns> key is provided as a shortcut for the common case of a
report with column headers and a single-row C<detail> section.

The value should be a hashref with the following keys:

=over

=item header

A hashref of parameters to pass to the constructor of the HBox that
holds the column headers.  Optional.

=item detail

A hashref of parameters to pass to the constructor of the HBox that
forms the C<detail> section.  Optional.

=item data

An arrayref of arrayrefs, one per column.  Required.  Each arrayref
has 4 elements.  The first two are the column title and the column
width.  The third is an optional hashref of parameters for the header
component, and the fourth is an optional hashref of parameters for the
detail component.

If you don't specify a C<_class> for the header component, it defaults
to L</default_column_header>, and if you don't specify a C<_class> for
the detail component, it defaults to L</default_column_type>.

If you don't specify a C<value> for the header component, it defaults
to the column title (as a L<Constant|PostScript::Report::Value::Constant>).

If you don't specify a C<value> for the detail component, it defaults
to the next column number.  (If you do specify a C<value>, the column
number is B<not> incremented.)

=back

This assumes that the C<page_header> is a VBox (or that there is no
C<page_header> aside from the column headers).

If you need a more complex layout than this, don't use C<columns>.
Instead, define the C<detail> and C<page_header> sections as needed.

=for Pod::Coverage
build_
create_
get_
require_class
