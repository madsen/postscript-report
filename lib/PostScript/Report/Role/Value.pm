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

=method get_value

  $value = $value_object->get_value($report)

A Value must provide this method.  It returns the value that should be
displayed on the report.  It may consult the C<$report> object to
collect information.

=cut

requires 'get_value';
#---------------------------------------------------------------------

=method dump

  $value_object->dump($level)

This method (for debugging purposes only) prints a representation of
the value to the currently selected filehandle.

C<$level> indicates the level of indentation to use.

The default implementation should be sufficient in most cases.

=cut

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

=head1 DESCRIPTION

The Value role describes an object that provides a C<get_value>
method.  It's used as the L<PostScript::Report::Role::Component/value>
when something more than a simple hash or array lookup is required.
See L<PostScript::Report/get_value>.

=for Pod::Loom-sort_method
get_value
dump

=for Pod::Loom-omit
CONFIGURATION AND ENVIRONMENT
