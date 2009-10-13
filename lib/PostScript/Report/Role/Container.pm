#---------------------------------------------------------------------
package PostScript::Report::Role::Container;
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
# ABSTRACT: Something that holds components
#---------------------------------------------------------------------

our $VERSION = '0.01';

use Moose::Role;
use Moose::Autobox;
use MooseX::AttributeHelpers;
use MooseX::Types::Moose qw(ArrayRef Bool Int Str);
use PostScript::Report::Types ':all';

with 'PostScript::Report::Role::Component';

my @inherited = (traits => [qw/TreeInherit/]);

has children => (
  metaclass => 'Collection::Array',
  is        => 'ro',
  isa       => ArrayRef[Component],
  default   => sub { [] },
  provides  => {
    push => 'add_child',
  },
);

has row_height => (
  is        => 'ro',
  isa       => Int,
  @inherited,
);

after init => sub {
  my ($self, $parent, $report) = @_;

  $_->init($self, $report) for $self->children->flatten;
}; # end after init

#=====================================================================
# Package Return Value:

1;

__END__

