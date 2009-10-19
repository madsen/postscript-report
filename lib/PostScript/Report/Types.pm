#---------------------------------------------------------------------
package PostScript::Report::Types;
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
# ABSTRACT: type library for PostScript::Report
#---------------------------------------------------------------------

our $VERSION = '0.01';

use MooseX::Types -declare => [qw(
  BorderStyle Component Container FontObj FontMetrics HAlign
  Parent Report RptValue VAlign
)];
use MooseX::Types::Moose qw(Str);

enum(BorderStyle, qw(0 1));

subtype Component,
  as role_type('PostScript::Report::Role::Component');

subtype Container,
  as role_type('PostScript::Report::Role::Container');

subtype FontObj,
  as class_type('PostScript::Report::Font');

subtype FontMetrics,
  as class_type('Font::AFM');

enum(HAlign, qw(center left right));

subtype Report,
  as class_type('PostScript::Report');

subtype RptValue,
  as Str|role_type('PostScript::Report::Role::Value');

subtype Parent,
  as Container|Report;

enum(VAlign, qw(bottom top));

1;

__END__

=head1 DESCRIPTION

These are the custom types used by L<PostScript::Report>.

=head1 TYPES

=head2 BorderStyle

A valid border style (C<0> or C<1>)

=head2 Component

An object that does L<PostScript::Report::Role::Component>.

=head2 Container

An object that does L<PostScript::Report::Role::Container>.

=head2 FontObj

A L<PostScript::Report::Font>.

=head2 FontMetrics

A L<Font::AFM>.

=head2 HAlign

C<center>, C<left>, or C<right>

=head2 Report

A L<PostScript::Report>.

=head2 RptValue

Something you can pass to L<PostScript::Report/get_value>.
A string or an object that does L<PostScript::Report::Role::Value>.

=head2 Parent

An object that is a suitable C<parent> for a Component.

=head2 VAlign

C<bottom> or C<top>

=head1 SEE ALSO

L<MooseX::Types>, L<MooseX::Types::Moose>.

=for Pod::Loom-omit
CONFIGURATION AND ENVIRONMENT
INCOMPATIBILITIES
BUGS AND LIMITATIONS
