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

my $blank = {
  _class => 'Constant',
  value => ''
};

my $desc = {
  fonts => {
    label     => 'Helvetica-6',
    text      => 'Helvetica-9',
    boldText  => 'Helvetica-Bold-9',
    pageNum   => 'Helvetica-8',
    bottomRow => 'Helvetica-6',
    disclaimerText => 'Helvetica-Bold-8',
  },

  font       => 'text',
  label_font => 'label',
  align      => 'center',

  landscape     => 1,
  top_margin    => 25,
  left_margin   => 20,
  right_margin  => 20,
  bottom_margin => 25,
  row_height    => 22,

  report_header => [
    HBox => { border => 0,
              font => 'boldText',
              height => 12,
              padding_bottom => 4,
              padding_side   => 0,
            },
    { _class => 'Field',
      width  => 200,
      align  => 'left',
      value  => { _class => 'Constant',
                  value => 'AIRPLANE COMPONENT FIXING INC.' } },
    { _class => 'Field',
      width  => 351,
      value  => { _class => 'Constant',
                  value => 'WORK ORDER' } },
    { _class => 'Field',
      width  => 200,
      align  => 'right',
      value  => { _class => 'Constant',
                  value => 'F.A.A REPAIR STATION NO. L3PF428Q' } },
  ],

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
        align => 'left',
        width => 130 },
      { label => 'Location:',
        value => 'location',
        width => 54 },
      { label => 'Work Order#:',
        value => 'workOrder',
        font  => 'boldText',
        width => 105 },
    ],
    [ HBox => { border => 0 },
      { label => 'Part Description:',
        value => 'partDesc',
        border=> 1,
        width => 160 },
      { label => 'Part Number Returned:',
        value => 'partNumReturned',
        border=> 1,
        width => 146 },
      { label => 'Serial Number Returned:',
        value => 'serialNumReturned',
        border=> 1,
        width => 156 },
      { label => 'Material Type:',
        value => 'materialType',
        align => 'left',
        actual_height => 44,
        multiline     => 1,
        border        => 1,
        width => 130 },
      { label => 'Customer Order Number:',
        value => 'custOrderNum',
        border=> 1,
        width => 159 },
    ],
    [ HBox => { border => 0 },
      { label => 'Date Received:',
        value => 'dateReceived',
        border=> 1,
        width => 69 },
      { label => 'RO Due Date:',
        value => 'roDueDate',
        border=> 1,
        width => 91 },
      { label => 'Repair/Overhaul Per:',
        value => 'repairPer',
        align => 'left',
        border=> 1,
        width => 302 },
      { _class => 'Spacer',
        width  => 130 },
      { label => 'Part Verified By:',
        value => 'verifiedBy',
        border=> 1,
        width => 80 },
      { label => 'Revised Due Date:',
        value => 'revisedDueDate',
        border=> 1,
        width => 79 },
    ],
  ], # end page_header

  columns => {
    header => {
      font           => 'boldText',
      height         => 19,
      padding_bottom => 6,
      padding_side   => 3,
    },
    detail => {
      height         => 19,
      padding_bottom => 6,
      padding_side   => 3,
    },
    data => [
      [ 'SEQ#' => 29 ],
      [ 'STA#' => 40 ],
      [ 'REPAIR SCOPE' => 450, { align => 'left'}, { align => 'left'} ],
      [ MECHANIC => 73 ],
      [ INSPECTOR => 80 ],
      [ DATE => 79, undef, { _class => 'Spacer' } ],
    ],
  }, # end columns

  page_footer => [
    VBox => { border => 0 },
    { _class => 'Field',
            font   => 'disclaimerText',
      padding_bottom => 4,
      value  => { _class => 'Constant',
                  value => 'The component identified above was repaired/overhauled/inspected IAW current federal aviation regulations and in respect to that work, was found airworthy for return to service.' },
    },
    [ HBox => { border => 1 },
      { label => 'Inspector',
        value => $blank,
        width => 339 },
      { label => 'Final Inspection Stamp',
        value => $blank,
        width => 154 },
      { label => 'Date',
        value => $blank,
        width => 258 },
    ],
    [ HBox => {
        border => 1,
        height => 14,
        font => 'bottomRow',
        padding_side => 0,
        padding_bottom => 4,
      },
      [ HBox => { border => 0, font  => 'pageNum' },
        { _class => 'Field',
          value => { _class => 'Constant', value => '42410-1' },
          width => 57 },
        { _class => 'Spacer',
          width  => 14 },
        { _class => 'Field',
          align => 'left',
          value => { _class => 'Page', value => 'Page(s): %n OF %t' },
          width => 377 },
      ],
    ],
  ], # end page_footer
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

my $rows = [
  [ 1, 'I1', 'INSPECT, PN & SN VERIFIED', 'XXXXXXXX', '' ],
  [ 2, 'I1', 'ADDITIONAL DATA USED: BOEING ASSEMBLY DRAWING 589X1674, GDR9726', 'XXXXXXXX', '' ],
  [ 3, 'I1', 'Lorem ipsum dolor sit amet, consectetur adipisicing elit', 'XXXXXXXX', '' ],
  [ 4, 'I1', 'Lorem ipsum dolor sit amet', 'XXXXXXXX', '' ],
  [ 5, 'I1', 'Lorem ipsum dolor sit amet', 'XXXXXXXX', '' ],
  [ 6, 'I1', 'Lorem ipsum dolor sit amet', 'XXXXXXXX', '' ],
  [ 7, 'I1', 'Lorem ipsum dolor sit amet', 'XXXXXXXX', '' ],
  [ 8, 'S1', 'Lorem ipsum dolor sit amet', '', 'XXXXXXXX' ],
  [ 9, 'W1', 'Lorem ipsum dolor sit amet', '', '' ],
  [ 10, 'W1', 'Lorem ipsum dolor sit amet', '', 'XXXXXXXX' ],
  [ 11, 'W1', 'Lorem ipsum dolor sit amet', '', 'XXXXXXXX' ],
  [ 12, 'W1', 'Lorem ipsum dolor sit amet', '', 'XXXXXXXX' ],
  [ 13, 'W1', 'Lorem ipsum dolor sit amet', '', 'XXXXXXXX' ],
  [ 14, 'W1', 'Lorem ipsum dolor sit amet', '', 'XXXXXXXX' ],
  [ 15, 'W1', 'Lorem ipsum dolor sit amet', '', '' ],
  [ 16, 'P1', 'Lorem ipsum dolor sit amet', '', 'XXXXXXXX' ],
  [ 17, 'P1', 'Lorem ipsum dolor sit amet', '', 'XXXXXXXX' ],
  [ 18, 'P1', 'Lorem ipsum dolor sit amet', '', 'XXXXXXXX' ],
  [ 19, 'P1', 'Lorem ipsum dolor sit amet', '', '' ],
  [ 20, 'P1', 'Lorem ipsum dolor sit amet', '', '' ],
  [ 21, 'F1', 'Lorem ipsum dolor sit amet', 'XXXXXXXX', '' ],
  [ 22, 'P1', 'Lorem ipsum dolor sit amet', '', 'XXXXXXXX' ],
  [ 23, 'P1', 'Lorem ipsum dolor sit amet', '', 'XXXXXXXX' ],
  [ 24, 'S1', 'Lorem ipsum dolor sit amet', '', 'XXXXXXXX' ],
  [ 25, 'SR', 'Lorem ipsum dolor sit amet', '', 'XXXXXXXX' ],
  [ 26, 'I1', 'Lorem ipsum dolor sit amet', 'XXXXXXXX', '' ],
];

my $rpt = PostScript::Report::Builder->build($desc);

$rpt->generate($data, $rows);

$rpt->ps->output("/tmp/psreport");

use Data::Dumper;
$Data::Dumper::Indent = 1;

print Dumper($rpt);
