#---------------------------------------------------------------------
package PostScript::Report::Field;
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
# ABSTRACT: A simple field with no label
#---------------------------------------------------------------------

our $VERSION = '0.02';

use Moose;
use MooseX::Types::Moose qw(Bool Int Num Str);
use PostScript::Report::Types ':all';

use namespace::autoclean;

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

after init => sub {
  my ($self, $parent, $report) = @_;

  # Use __PACKAGE__ instead of blessed $self because the string is
  # constant.  Subclasses should either use sub id { 'Field' } or
  # define their own comparable functions:
  $report->ps_functions->{+__PACKAGE__} = <<'END PS';
%---------------------------------------------------------------------
% X Y STRING FONT L T R B Field-X

/Field { gsave  4 copy  clipbox  8 4 roll setfont } bind def
/Field-C { Field showcenter grestore } bind def
/Field-L { Field showleft   grestore } bind def
/Field-R { Field showright  grestore } bind def
END PS
}; # end after init

sub draw
{
  my ($self, $x, $y, $rpt) = @_;

  my $align = uc substr($self->align, 0, 1);

  my $xOff = do {
    if    ($align eq 'C') { $self->width / 2 }
    elsif ($align eq 'R') { $self->width - $self->padding_side }
    else                  { $self->padding_side }
  };

  my $ps = $rpt->ps;
  $ps->add_to_page( sprintf(
    "%s %s\n%s\n%s %d %d %d %d %s-%s %s db%s\n",
    $x + $xOff, $y - $self->height + $self->padding_bottom,
    $ps->pstr( $rpt->get_value($self->value) ),
    $self->font->id,
    $x, $y, $x + $self->width, $y - $self->height,
    $self->id, $align,
    $self->line_width, $self->border,
  ));
} # end draw

#=====================================================================
no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 DESCRIPTION

This L<Component|PostScript::Report::Role::Component> is a simple text field.

Note:  While you may use a Field as a label by giving it a
L<constant value|PostScript::Report::Value::Constant>, it always uses
C<font> to draw the text, not C<label_font>.

=head1 ATTRIBUTES

A Field has all the normal
L<component attributes|PostScript::Report::Role::Component/ATTRIBUTES>,
including C<padding_bottom>, C<padding_side>, and C<value>.

=for Pod::Coverage draw

=for Pod::Loom-omit
CONFIGURATION AND ENVIRONMENT
