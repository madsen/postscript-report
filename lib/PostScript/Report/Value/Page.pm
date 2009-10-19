#---------------------------------------------------------------------
package PostScript::Report::Value::Page;
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
# ABSTRACT: Evaluate a page number expression
#---------------------------------------------------------------------

our $VERSION = '0.01';

use Moose;
use MooseX::Types::Moose qw(Str);

with 'PostScript::Report::Role::Value';

=attr value

This string can contain the following C<%> codes, which will be
substituted when it is returned by C<get_value>.

=over

=item C<%n>

The current page number

=item C<%t>

The total number of pages in the report

=item C<%%>

A literal C<%> sign

=back

=cut

has value => (
  is       => 'ro',
  isa      => Str,
  required => 1,
);

sub get_value
{
  my ($self, $rpt) = @_;

  my $text = $self->value;

  # Handle the following % codes:
  my %sub = (
    '%' => '%',
    'n' => $rpt->page_number,
    't' => $rpt->page_count,
  );

  # Substitute the % codes (unrecognized codes are unchanged):
  $text =~ s{\%(.)}{
    defined($sub{$1}) ? $sub{$1} : "\%$1"
  }ge;

  $text;
} # end get_value

#=====================================================================
no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 DESCRIPTION

This L<Value|PostScript::Report::Role::Value> substitutes page numbers
into a string.

=for Pod::Coverage get_value

=for Pod::Loom-omit
CONFIGURATION AND ENVIRONMENT
