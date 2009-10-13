#---------------------------------------------------------------------
package PostScript::Report::Value::Constant;
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
# ABSTRACT: Return a constant value
#---------------------------------------------------------------------

our $VERSION = '0.01';

use Moose;

with 'PostScript::Report::Role::Value';

has value => (
  is      => 'ro',
  isa     => Str,
  required => 1,
);

# Just ignore the $rpt parameter:
sub get_value { shift->value }
