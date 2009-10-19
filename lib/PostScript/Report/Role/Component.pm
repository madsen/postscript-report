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

sub draw_standard_border
{
  my ($self, $x, $y, $rpt) = @_;

  if ($self->border) {
    $rpt->ps->add_to_page( sprintf(
      "%d %d %d %d %s db%s\n",
      $x, $y, $x + $self->width, $y - $self->height,
      $self->line_width, $self->border
    ));
  }
} # end draw_standard_border

sub id
{
  my $class = blessed shift;
  $class =~ /([^:]+)$/ or confess "No class";

  $1;
} # end id

sub init
{
  my ($self, $parent, $report) = @_;

  $self->_set_parent($parent);
} # end init

#---------------------------------------------------------------------
sub dump
{
  my ($self, $level) = @_;
  $level ||= 0;

  my $indent = "  " x $level;

  printf "%s%s:\n", $indent, blessed $self;

  my @attrs = sort { $a->name cmp $b->name } $self->meta->get_all_attributes;

  my $is_container;
  ++$level;

  foreach my $attr (@attrs) {
    my $name = $attr->name;

    next if $name eq 'parent';

    if ($name eq 'children' and
        $self->does('PostScript::Report::Role::Component')) {
      $is_container = 1;
    } else {
      PostScript::Report->_dump_attr($self, $attr, $level);
    }
  } # end foreach $attr in @attrs

  return unless $is_container;

  print "$indent  children:\n";

  ++$level;
  foreach my $child (@{ $self->children }) {
    $child->dump($level);
  } # end foreach $child
} # end dump

#=====================================================================
# Package Return Value:

1;

__END__

