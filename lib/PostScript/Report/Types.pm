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
  Parent Report RptValue
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

1;
