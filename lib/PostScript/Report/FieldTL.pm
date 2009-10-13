#---------------------------------------------------------------------
package PostScript::Report::FieldTL;
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
# ABSTRACT: A field with a label in the top left corner
#---------------------------------------------------------------------

our $VERSION = '0.01';

use Moose;
#use Moose::Autobox;
use MooseX::Types::Moose qw(Bool Int Str);
use PostScript::Report::Types ':all';

use PostScript::File 'pstr';

use namespace::autoclean;

with 'PostScript::Report::Role::Component';

has label => (
  is      => 'ro',
  isa     => Str,
  default => '',
);

has value => (
  is       => 'ro',
  isa      => RptValue,
  required => 1,
);

has actual_height => (
  is       => 'ro',
  isa      => Int,
);

has multiline => (
  is       => 'ro',
  isa      => Bool,
);

sub draw
{
  my ($self, $x, $y, $rpt) = @_;

  printf("%3d %3d %-23s %s\n", $x, $y, $self->label,
         $rpt->get_value($self->value)); # FIXME
} # end draw

#=====================================================================
no Moose;
__PACKAGE__->meta->make_immutable;
1;
