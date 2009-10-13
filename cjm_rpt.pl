#! /usr/bin/perl
#---------------------------------------------------------------------
# Copyright 2009 Christopher J. Madsen
#
# Example script for PostScript::Report
#---------------------------------------------------------------------

use strict;
use warnings;
use 5.010;

use autodie ':io';

use lib 'lib';

use PostScript::Report::Builder ();

my $desc = {
  fonts => {
    label     => 'Helvetica-6',
    text      => 'Helvetica-9',
    boldText  => 'Helvetica-Bold-9',
  },

  font       => 'text',
  label_font => 'label',

  landscape     => 1,
  top_margin    => 30,
  left_margin   => 20,
  right_margin  => 20,
  bottom_margin => 30,
  row_height    => 22,

  page_header => [
    [ { label => 'Customer Name:',
        value => 'custName',
        width => 160 },
      { label => 'Part Number Received:',
        value => 'partNumReceived',
        width => 146 },
      { label => 'Serial Number Received:',
        value => 'serialNumReceived',
        width => 156 },
      { label => 'Installed On:',
        value => 'installedOn',
        width => 130 },
      { label => 'Location:',
        value => 'location',
        width => 54 },
      { label => 'Work Order#:',
        value => 'workOrder',
        font  => 'boldText',
        width => 105 },
    ],
    [ { label => 'Part Description:',
        value => 'partDesc',
        width => 160 },
      { label => 'Part Number Returned:',
        value => 'partNumReturned',
        width => 146 },
      { label => 'Serial Number Returned:',
        value => 'serialNumReturned',
        width => 156 },
      { label => 'Material Type:',
        value => 'materialType',
        actual_height => 44,
        multiline     => 1,
        width => 130 },
      { label => 'Customer Order Number:',
        value => 'custOrderNum',
        width => 159 },
    ],
    [ { label => 'Date Received:',
        value => 'dateReceived',
        width => 69 },
      { label => 'RO Due Date:',
        value => 'roDueDate',
        width => 91 },
      { label => 'Repair/Overhaul Per:',
        value => 'repairPer',
        width => 302 },
      { _class => 'Spacer',
        width  => 130 },
      { label => 'Part Verified By:',
        value => 'verifiedBy',
        width => 80 },
      { label => 'Revised Due Date:',
        value => 'revisedDueDate',
        width => 79 },
    ],
  ], # end page_header
};

my $data = {
  'custName'          => 'IMAGINARY AIRWAYS',
  'partNumReceived'   => '957X1427-3',
  'serialNumReceived' => 'N/A',
  'installedOn'       => '797',
  'location'          => 'A1',
  'workOrder'         => '68452-8',
  'partDesc'          => 'TURBOFAN',
  'partNumReturned'   => '957X1427-3',
  'serialNumReturned' => 'N/A',
  'materialType'      => 'FOO BAR 123',
  'custOrderNum'      => '8452647',
  'dateReceived'      => '05/06/2009',
  'roDueDate'         => '05/06/2009',
  'repairPer'         => 'REPAIR PER B797 CMM 47-42-96 REV 40 DATED 07MAY2009',
  'verifiedBy'        => '951',
  'revisedDueDate'    => '',
};

my $rows = [];

my $rpt = PostScript::Report::Builder->build($desc);

$rpt->generate($data, $rows);

use Data::Dumper;
$Data::Dumper::Indent = 1;

print Dumper($rpt);
