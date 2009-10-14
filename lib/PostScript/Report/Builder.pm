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

our $VERSION = '0.01';

use 5.008;
use Moose;
use MooseX::Types::Moose qw(Bool HashRef Int Str);
use PostScript::Report::Types ':all';

use PostScript::Report::HBox ();
use PostScript::Report::VBox ();
use String::RewritePrefix ();

use namespace::autoclean;

our %loaded_class;

has default_field_type => (
  is  => 'ro',
  isa => Str,
  default => 'FieldTL',
);

has report_class => (
  is      => 'ro',
  isa     => Str,
  default => 'PostScript::Report',
);

has _fonts => (
  is       => 'rw',
  isa      => HashRef[FontObj],
  init_arg => undef,
  clearer  => '_clear_fonts',
);

our @constructor_args = qw(
  align
  bottom_margin
  landscape
  left_margin
  paper_size
  right_margin
  row_height
  title
  top_margin
);

#---------------------------------------------------------------------

sub build
{
  my ($self, $desc) = @_;

  # If we're called as a package method, construct a temporary object:
  unless (ref $self) {
    $self = $self->new($desc);
  }

  # Construct the PostScript::Report object:
  $self->require_class( $self->report_class );

  my $rpt = $self->report_class->new(
    map { exists $desc->{$_} ? ($_ => $desc->{$_}) : () } @constructor_args
  );

  # Create the fonts we'll be using:
  $self->create_fonts( $rpt, $desc->{fonts} );

  # Set the report's default fonts:
  foreach my $type (qw(font label_font)) {
    next unless exists $desc->{$type};

    $rpt->$type( $self->get_font( $desc->{$type} ) );
  }

  foreach my $sectionName (qw(report_header page_header detail
                              page_footer report_footer)) {
    my $section = $desc->{$sectionName} or next;

    $rpt->$sectionName( $self->build_section( $section ));
  } # end foreach $sectionName

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
  return $self->build_box($desc, $boxType);
} # end build_section

#---------------------------------------------------------------------
sub build_box
{
  my ($self, $desc, $boxType) = @_;

  die "Empty box is not allowed" unless @$desc;

  my $start = 0;
  my $boxParam;

  # If [ className => { ... } ], use it:
  if (not ref $desc->[0]) {
    $boxType  = $desc->[0];
    $boxParam = $desc->[1];
    $start = 2;
  } else {
    $boxParam = {};
  }

  # Construct the children:
  my $defaultClass = $self->default_field_type;

  my @children = map {
    ref $_ eq 'HASH'
        ? $self->build_object($_, $defaultClass)
        : $self->build_box($_, ($boxType eq 'HBox' ? 'VBox' : 'HBox'))
  } @$desc[$start .. $#$desc];

  # Construct the box:
  $self->get_class($boxType)->new(children => \@children, %$boxParam);
} # end build_box

#---------------------------------------------------------------------
sub build_object
{
  my ($self, $desc, $class, $prefix) = @_;

  my %parms = %$desc;

  $class = $self->get_class(delete($parms{_class}) || $class, $prefix);

  while (my ($key, $val) = each %parms) {
    if ($key =~ /(?:^|_)font$/) {
      $parms{$key} = $self->get_font($val);
    } elsif (ref $val) {
      if ($key eq 'value') {
        $parms{$key} = $self->build_object($val, undef,
                                           'PostScript::Report::Value::');
      } else {
        $parms{$key} = $self->build_object($val);
      }
    } # end else ref $val
  } # end while each ($key, $val) in %parms

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

    use PostScript::Report;

=for author to fill in:
    Brief code example(s) here showing commonest usage(s).
    This section will be as far as many users bother reading
    so make it as educational and exeplary as possible.


=head1 DESCRIPTION

=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.
