#---------------------------------------------------------------------
package PostScript::Report::Role::Value;
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
# ABSTRACT: Something that returns a field value
#---------------------------------------------------------------------

our $VERSION = '0.01';

use Moose::Role;

requires 'get_value';

#---------------------------------------------------------------------
sub dump
{
  my ($self, $level) = @_;

  my @attrs = sort { $a->name cmp $b->name } $self->meta->get_all_attributes;

  PostScript::Report->_dump_attr($self, $_, $level) for @attrs;
} # end dump

#=====================================================================
# Package Return Value:

1;

__END__

