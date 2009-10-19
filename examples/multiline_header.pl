#! /usr/bin/perl
#---------------------------------------------------------------------
# This example report is hereby placed in the public domain.
# You may copy from it freely.
#
# This is a fairly complex example for PostScript::Report.
# It includes a header field that spans two rows and uses word wrap.
#---------------------------------------------------------------------

use strict;
use warnings;

use PostScript::Report ();

# Define a Value::Constant with a blank string:
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

  padding_bottom => 4,
  padding_side   => 3,

  landscape     => 1,
  top_margin    => 25,
  left_margin   => 20,
  right_margin  => 20,
  bottom_margin => 25,
  row_height    => 22,

  # The report_header is one line with text fields left, center, & right.
  # All values are constant.
  report_header => [
    HBox => { border => 0,
              font => 'boldText',
              height => 12,
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

  # The page_header is fairly complex.
  # The Material Type field spans rows 2 and 3.
  page_header => [
    # This HBox is row 1 of the header:
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
    # This HBox contains rows 2 & 3, because Material Type is 2 rows high:
    [
      # This VBox is the left hand side of rows 2 & 3:
      [
        # This HBox is the left hand side of row 2:
        [ { label => 'Part Description:',
            value => 'partDesc',
            width => 160 },
          { label => 'Part Number Returned:',
            value => 'partNumReturned',
            width => 146 },
          { label => 'Serial Number Returned:',
            value => 'serialNumReturned',
            width => 156 },
        ], # end row 2 left
        # This HBox is the left hand side of row 3:
        [ { label => 'Date Received:',
            value => 'dateReceived',
            width => 69 },
          { label => 'RO Due Date:',
            value => 'roDueDate',
            width => 91 },
          { label => 'Repair/Overhaul Per:',
            value => 'repairPer',
            align => 'left',
            width => 302 },
        ] ], # end rows 2 & 3 left
      # This field is two rows high:
      { label => 'Material Type:',
        value => 'materialType',
        align => 'left',
        height    => 44,
        multiline => 1,
        width => 130 },
      # This VBox is the right hand side of rows 2 & 3:
      [
        # Don't need an HBox for row 2 right; it's only one field:
        { label => 'Customer Order Number:',
          value => 'custOrderNum',
          width => 159 },
        # This HBox is the right hand side of row 3:
        [ { label => 'Part Verified By:',
            value => 'verifiedBy',
            width => 80 },
          { label => 'Revised Due Date:',
            value => 'revisedDueDate',
            width => 79 },
        ] ], # end rows 2 & 3 right
    ], # end rows 2 & 3
  ], # end page_header

  columns => {
    header => {
      font           => 'boldText',
      height         => 19,
      padding_bottom => 6,
    },
    detail => {
      height         => 19,
      padding_bottom => 6,
    },
    data => [
      [ 'SEQ#' => 29 ],
      [ 'STA#' => 40 ],
      [ 'REPAIR SCOPE' => 450, { align => 'left'}, { align => 'left'} ],
      [ MECHANIC => 73 ],
      [ INSPECTOR => 80 ],
      # The DATE column is filled in by hand after printing.  We'll
      # use a Spacer in the detail section so we don't need a blank
      # column in each row.  (Note: If this weren't the last column,
      # we'd also need to pass a fake value to the Spacer to tell the
      # builder not to increment the column number.)
      [ DATE => 79, undef, { _class => 'Spacer' } ],
    ],
  }, # end columns

  # The footer is also a bit complex:
  page_footer => [
    # We don't want a border around the whole footer:
    VBox => { border => 0 },
    # The first row is just one component:
    { _class => 'Field',
      font   => 'disclaimerText',
      value  => { _class => 'Constant',
                  value => 'The component identified above was repaired/overhauled/inspected IAW current federal aviation regulations and in respect to that work, was found airworthy for return to service.' },
    },
    # The second row is filled in by hand, so the values are blank:
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
    # The third row includes the page number and checkboxes:
    [ HBox => {
        border => 1,
        height => 14,
        font => 'bottomRow',
        padding_side => 0,
      },
      # This HBox exists just to set parameters on its children:
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
      # This HBox exists just to set parameters on its children:
      [ HBox => { border => 0, padding_bottom => 6, padding_side => 2 },
        { _class => 'Field',
          align => 'right',
          value => { _class => 'Constant', value => 'ML' },
          width => 10 },
        { _class => 'Field',
          align => 'right',
          value => { _class => 'Constant', value => 'FXN-' },
          width => 53 },
        { _class => 'Field',
          align => 'left',
          value => 'FXN',
          width => 28 },
        { _class => 'Field',
          align => 'right',
          value => { _class => 'Constant', value => 'AP' },
          width => 17 },
        { _class => 'Checkbox',
          value => 'AP',
          padding_bottom => 3,
          width => 20 },
        { _class => 'Field',
          align => 'right',
          value => { _class => 'Constant', value => 'BP' },
          width => 20 },
        { _class => 'Checkbox',
          value => 'BP',
          padding_bottom => 3,
          width => 20 },
        { _class => 'Field',
          align => 'right',
          value => { _class => 'Constant', value => 'Photo' },
          width => 45 },
        { _class => 'Field',
          align => 'left',
          value => 'photo',
          width => 28 },
        { _class => 'Field',
          align => 'right',
          value => { _class => 'Constant', value => 'QTY' },
          width => 35 },
        { _class => 'Field',
          align => 'left',
          value => 'qty',
          width => 27 },
      ],
    ], # end third row of page_footer
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
  AP                  => 0,
  BP                  => 1,
  FXN                 => 0,
  photo               => 6,
  qty                 => 1,
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

my $rpt = PostScript::Report->build($desc);

$rpt->run($data, $rows)->output("multiline_header.ps");

# $rpt->dump;
