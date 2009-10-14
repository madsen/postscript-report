#---------------------------------------------------------------------
package PostScript::Report::Role::Component;
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
# ABSTRACT: Something that can be drawn
#---------------------------------------------------------------------

our $VERSION = '0.01';

use Moose::Role;
use MooseX::AttributeTree ();
use MooseX::Types::Moose qw(Bool Int Num Str);
use PostScript::Report::Types ':all';

my @inherited = (traits => [qw/TreeInherit/]);

has parent => (
  is       => 'ro',
  isa      => Parent,
  weak_ref => 1,
  writer   => '_set_parent',
);

has height => (
  is        => 'ro',
  isa       => Int,
  writer    => '_set_height',
  predicate => 'has_height',
  @inherited,
);

has width => (
  is        => 'ro',
  isa       => Int,
  writer    => '_set_width',
  predicate => 'has_width',
  @inherited,
);

has align => (
  is  => 'ro',
  isa => HAlign,
  @inherited,
);

has border => (
  is  => 'ro',
  isa => BorderStyle,
  @inherited,
);

has font => (
  is  => 'ro',
  isa => FontObj,
  @inherited,
);

has label_font => (
  is  => 'ro',
  isa => FontObj,
  @inherited,
);

has line_width => (
  is  => 'ro',
  isa => Num,
  @inherited,
);

requires 'draw';

sub init
{
  my ($self, $parent, $report) = @_;

  $self->_set_parent($parent);
} # end init

#=====================================================================
# Package Return Value:

1;

__END__

