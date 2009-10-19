#---------------------------------------------------------------------
package PostScript::Report::Spacer;
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
# ABSTRACT: Leave blank space in a report
#---------------------------------------------------------------------

our $VERSION = '0.01';

use Moose;
with 'PostScript::Report::Role::Component';

sub draw { shift->draw_standard_border(@_) }

#=====================================================================
no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 DESCRIPTION

This L<Component|PostScript::Report::Role::Component> is simply a
blank space (possibly with a border).

=for Pod::Coverage draw

=for Pod::Loom-omit
CONFIGURATION AND ENVIRONMENT
