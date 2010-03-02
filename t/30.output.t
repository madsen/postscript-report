#! /usr/bin/perl
#---------------------------------------------------------------------
# Copyright 2009 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@pobox.com>
# Created: 28 Oct 2009
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# Test the structure and output of a complex report
#---------------------------------------------------------------------

use strict;
use warnings;

use Test::More;

my $diff;
BEGIN { $diff = eval "use Test::Differences; 1" }

use PostScript::Report ();

my $generateResults = '';

if (@ARGV and $ARGV[0] eq 'gen') {
  # Just output the actual results, so they can be diffed against this file
  $generateResults = 1;
  open(OUT, '>', '/tmp/30.output.t') or die $!;
  printf OUT "#%s\n\n__DATA__\n", '=' x 69;
} elsif (@ARGV and $ARGV[0] eq 'ps') {
  $generateResults = 'ps';
  open(OUT, '>', '/tmp/30.output.ps') or die $!;
} else {
  plan tests => 3;
}

sub dumpReport
{
  my ($rpt) = @_;

  my $output = '';
  open (my $out, '>', \$output);
  select $out;
  $rpt->dump;
  select STDOUT;
  $output =~ s/ +$//mg;         # Remove trailing space

  $output;
} # end dumpReport

# Define a Value::Constant with a blank string:
my $blank = \'';

my $desc = {
  fonts => {
    label     => 'Helvetica-6',
    text      => 'Helvetica-9',
    boldText  => 'Helvetica-Bold-9',
    pageNum   => 'Helvetica-8',
    bottomRow => 'Helvetica-6',
    disclaimerText => 'Helvetica-Bold-8',
  },

  ps_parameters => { strip => 'comments' },

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

  default_field_type => 'FieldTL',

  stripe => [ 1, '#fa4' ],

  # The report_header is one line with text fields left, center, & right.
  # All values are constant.
  report_header => [
    HBox => { border => 0,
              font => 'boldText',
              height => 12,
              padding_side   => 0,
              _default => 'Field', # override default_field_type
            },
    { width  => 200,
      align  => 'left',
      value  => \'AIRPLANE COMPONENT FIXING INC.' },
    { width  => 351,
      value  => \'WORK ORDER' },
    { width  => 200,
      align  => 'right',
      value  => \'F.A.A REPAIR STATION NO. L3PF428Q' },
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
      value  => \'The component identified above was repaired/overhauled/inspected IAW current federal aviation regulations and in respect to that work, was found airworthy for return to service.',
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
        _default => 'Field',
      },
      # This HBox exists just to set parameters on its children:
      [ HBox => { border => 0, font  => 'pageNum' },
        { value => \'42410-1',
          width => 57 },
        { _class => 'Spacer',
          width  => 14 },
        { align => 'left',
          value => { _class => 'Page', value => 'Page(s): %n OF %t' },
          width => 377 },
      ],
      # This HBox exists just to set parameters on its children:
      [ HBox => { border => 0, padding_bottom => 6, padding_side => 2 },
        { align => 'right',
          value => \'ML',
          width => 10 },
        { align => 'right',
          value => \'FXN-',
          width => 53 },
        { align => 'left',
          value => 'FXN',
          width => 28 },
        { align => 'right',
          value => \'AP',
          width => 17 },
        { _class => 'Checkbox',
          value => 'AP',
          padding_bottom => 3,
          width => 20 },
        { align => 'right',
          value => \'BP',
          width => 20 },
        { _class => 'Checkbox',
          value => 'BP',
          padding_bottom => 3,
          width => 20 },
        { align => 'right',
          value => \'Photo',
          width => 45 },
        { align => 'left',
          value => 'photo',
          width => 28 },
        { align => 'right',
          value => \'QTY',
          width => 35 },
        { align => 'left',
          value => 'qty',
          width => 27 },
      ],
    ], # end third row of page_footer
  ], # end page_footer
};

my $data = {
  'custName'          => 'IMAGINARY AIRWAYS',
  'partNumReceived'   => '957X1427-3',
  'serialNumReceived' => '-45',
  'installedOn'       => '797',
  'location'          => 'A1',
  'workOrder'         => '68452-8',
  'partDesc'          => 'TURBOFAN',
  'partNumReturned'   => '957X1427-3',
  'serialNumReturned' => 'N/A',
  'materialType'      => 'FOO BAR 123 AND SOME MORE WORDS TO MAKE IT WRAP NOW',
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

my $ldquo = chr(0x201C);
my $rdquo = chr(0x201D);
my $mdash = chr(0x2014);

my $rows = [
  [  1, 'I1', 'INSPECT, PN & SN VERIFIED', 'XXXXXXXX', '' ],
  [  2, 'I1', 'ADDITIONAL DATA USED: BOEING ASSEMBLY DRAWING 589X1674, GDR9726', 'XXXXXXXX', '' ],
  [  3, 'I1', "${ldquo}Fourscore and seven years ago our fathers brought forth on this", 'XXXXXXXX', '' ],
  [  4, 'I1', 'continent a new nation, conceived in liberty and dedicated to the ', 'XXXXXXXX', '' ],
  [  5, 'I1', 'proposition that all men are created equal. Now we are engaged in ', 'XXXXXXXX', '' ],
  [  6, 'I1', 'a great civil war, testing whether that nation or any nation so ', 'XXXXXXXX', '' ],
  [  7, 'I1', 'conceived and so dedicated can long endure. We are met on a great ', 'XXXXXXXX', '' ],
  [  8, 'S1', 'battlefield of that war. We have come to dedicate a portion of ', '', 'XXXXXXXX' ],
  [  9, 'W1', 'that field as a final resting-place for those who here gave their ', '', '' ],
  [ 10, 'W1', 'lives that that nation might live. It is altogether fitting and ', '', 'XXXXXXXX' ],
  [ 11, 'W1', 'proper that we should do this. But in a larger sense, we cannot ', '', 'XXXXXXXX' ],
  [ 12, 'W1', 'dedicate, we cannot consecrate, we cannot hallow this ground. ', '', 'XXXXXXXX' ],
  [ 13, 'W1', 'The brave men, living and dead who struggled here have consecrated ', '', 'XXXXXXXX' ],
  [ 14, 'W1', 'it far above our poor power to add or detract. The world will ', '', 'XXXXXXXX' ],
  [ 15, 'W1', 'little note nor long remember what we say here, but it can never ', '', '' ],
  [ 16, 'P1', 'forget what they did here. It is for us the living rather to be ', '', 'XXXXXXXX' ],
  [ 17, 'P1', 'dedicated here to the unfinished work which they who fought here ', '', 'XXXXXXXX' ],
  [ 18, 'P1', 'have thus far so nobly advanced. It is rather for us to be here ', '', 'XXXXXXXX' ],
  [ 19, 'P1', "dedicated to the great task remaining before us${mdash}that from these ", '', '' ],
  [ 20, 'P1', 'honored dead we take increased devotion to that cause for which ', '', '' ],
  [ 21, 'F1', "they gave the last full measure of devotion${mdash}that we here highly", 'XXXXXXXX', '' ],
  [ 22, 'P1', 'resolve that these dead shall not have died in vain, that this ', '', 'XXXXXXXX' ],
  [ 23, 'P1', 'nation under God shall have a new birth of freedom, and that ', '', 'XXXXXXXX' ],
  [ 24, 'S1', 'government of the people, by the people, for the people shall ', '', 'XXXXXXXX' ],
  [ 25, 'SR', "not perish from the earth.$rdquo", '', 'XXXXXXXX' ],
  [ 26, 'I1', "${mdash}Abraham Lincoln", 'XXXXXXXX', '' ],
];

my $rpt = PostScript::Report->build($desc);

checkResults(dumpReport($rpt), 'structure after build');

$rpt->run($data, $rows);

# Use sanitized output (unless $generateResults eq 'ps'):
my $ps = $rpt->ps->testable_output($generateResults eq 'ps');

checkResults($ps, 'generated PostScript');

checkResults(dumpReport($rpt), 'structure after run');

#---------------------------------------------------------------------
sub checkResults
{
  my ($got, $name) = @_;

  if ($generateResults) {
    # Write out the actual results:
    if ($generateResults eq 'ps') {
      print OUT $got if $name eq 'generated PostScript';
    } else {
      print OUT "$got---\n";
    }
  } else {
    # Read expected results from DATA:
    my $expected = '';
    while (<DATA>) {
      last if $_ eq "---\n";
      $expected .= $_;
    }

    # And compare it:
    if ($diff) {                # use Test::Differences
      eq_or_diff($got, $expected, $name);
    } else {                    # fall back to Test::More
      is($got, $expected, $name);
    }
  } # end else running tests
} # end checkResults

#=====================================================================

__DATA__
align         : center
border        : 1
font          : Helvetica-iso 9
label_font    : Helvetica-iso 6
line_width    : 0.5
padding_bottom: 4
padding_side  : 3
row_height    : 22

report_header:
  PostScript::Report::HBox:
    border        : 0
    font          : Helvetica-Bold-iso 9
    height        : 12
    padding_side  : 0
    children:
      PostScript::Report::Field:
        align         : left
        value         : PostScript::Report::Value::Constant
          value         : AIRPLANE COMPONENT FIXING INC.
        width         : 200
      PostScript::Report::Field:
        value         : PostScript::Report::Value::Constant
          value         : WORK ORDER
        width         : 351
      PostScript::Report::Field:
        align         : right
        value         : PostScript::Report::Value::Constant
          value         : F.A.A REPAIR STATION NO. L3PF428Q
        width         : 200

page_header:
  PostScript::Report::VBox:
    children:
      PostScript::Report::HBox:
        children:
          PostScript::Report::FieldTL:
            label         : Customer Name:
            value         : custName
            width         : 160
          PostScript::Report::FieldTL:
            label         : Part Number Received:
            value         : partNumReceived
            width         : 146
          PostScript::Report::FieldTL:
            label         : Serial Number Received:
            value         : serialNumReceived
            width         : 156
          PostScript::Report::FieldTL:
            align         : left
            label         : Installed On:
            value         : installedOn
            width         : 130
          PostScript::Report::FieldTL:
            label         : Location:
            value         : location
            width         : 54
          PostScript::Report::FieldTL:
            font          : Helvetica-Bold-iso 9
            label         : Work Order#:
            value         : workOrder
            width         : 105
      PostScript::Report::HBox:
        children:
          PostScript::Report::VBox:
            children:
              PostScript::Report::HBox:
                children:
                  PostScript::Report::FieldTL:
                    label         : Part Description:
                    value         : partDesc
                    width         : 160
                  PostScript::Report::FieldTL:
                    label         : Part Number Returned:
                    value         : partNumReturned
                    width         : 146
                  PostScript::Report::FieldTL:
                    label         : Serial Number Returned:
                    value         : serialNumReturned
                    width         : 156
              PostScript::Report::HBox:
                children:
                  PostScript::Report::FieldTL:
                    label         : Date Received:
                    value         : dateReceived
                    width         : 69
                  PostScript::Report::FieldTL:
                    label         : RO Due Date:
                    value         : roDueDate
                    width         : 91
                  PostScript::Report::FieldTL:
                    align         : left
                    label         : Repair/Overhaul Per:
                    value         : repairPer
                    width         : 302
          PostScript::Report::FieldTL:
            align         : left
            height        : 44
            label         : Material Type:
            multiline     : 1
            value         : materialType
            width         : 130
          PostScript::Report::VBox:
            children:
              PostScript::Report::FieldTL:
                label         : Customer Order Number:
                value         : custOrderNum
                width         : 159
              PostScript::Report::HBox:
                children:
                  PostScript::Report::FieldTL:
                    label         : Part Verified By:
                    value         : verifiedBy
                    width         : 80
                  PostScript::Report::FieldTL:
                    label         : Revised Due Date:
                    value         : revisedDueDate
                    width         : 79
      PostScript::Report::HBox:
        font          : Helvetica-Bold-iso 9
        height        : 19
        padding_bottom: 6
        children:
          PostScript::Report::Field:
            value         : PostScript::Report::Value::Constant
              value         : SEQ#
            width         : 29
          PostScript::Report::Field:
            value         : PostScript::Report::Value::Constant
              value         : STA#
            width         : 40
          PostScript::Report::Field:
            align         : left
            value         : PostScript::Report::Value::Constant
              value         : REPAIR SCOPE
            width         : 450
          PostScript::Report::Field:
            value         : PostScript::Report::Value::Constant
              value         : MECHANIC
            width         : 73
          PostScript::Report::Field:
            value         : PostScript::Report::Value::Constant
              value         : INSPECTOR
            width         : 80
          PostScript::Report::Field:
            value         : PostScript::Report::Value::Constant
              value         : DATE
            width         : 79

detail:
  PostScript::Report::HBox:
    height        : 19
    padding_bottom: 6
    children:
      PostScript::Report::Field:
        value         : 0
        width         : 29
      PostScript::Report::Field:
        value         : 1
        width         : 40
      PostScript::Report::Field:
        align         : left
        value         : 2
        width         : 450
      PostScript::Report::Field:
        value         : 3
        width         : 73
      PostScript::Report::Field:
        value         : 4
        width         : 80
      PostScript::Report::Spacer:
        width         : 79

page_footer:
  PostScript::Report::VBox:
    border        : 0
    children:
      PostScript::Report::Field:
        font          : Helvetica-Bold-iso 8
        value         : PostScript::Report::Value::Constant
          value         : The component identified above was repaired/overhauled/inspected IAW current federal aviation regulations and in respect to that work, was found airworthy for return to service.
      PostScript::Report::HBox:
        border        : 1
        children:
          PostScript::Report::FieldTL:
            label         : Inspector
            value         : PostScript::Report::Value::Constant
              value         :
            width         : 339
          PostScript::Report::FieldTL:
            label         : Final Inspection Stamp
            value         : PostScript::Report::Value::Constant
              value         :
            width         : 154
          PostScript::Report::FieldTL:
            label         : Date
            value         : PostScript::Report::Value::Constant
              value         :
            width         : 258
      PostScript::Report::HBox:
        border        : 1
        font          : Helvetica-iso 6
        height        : 14
        padding_side  : 0
        children:
          PostScript::Report::HBox:
            border        : 0
            font          : Helvetica-iso 8
            children:
              PostScript::Report::Field:
                value         : PostScript::Report::Value::Constant
                  value         : 42410-1
                width         : 57
              PostScript::Report::Spacer:
                width         : 14
              PostScript::Report::Field:
                align         : left
                value         : PostScript::Report::Value::Page
                  value         : Page(s): %n OF %t
                width         : 377
          PostScript::Report::HBox:
            border        : 0
            padding_bottom: 6
            padding_side  : 2
            children:
              PostScript::Report::Field:
                align         : right
                value         : PostScript::Report::Value::Constant
                  value         : ML
                width         : 10
              PostScript::Report::Field:
                align         : right
                value         : PostScript::Report::Value::Constant
                  value         : FXN-
                width         : 53
              PostScript::Report::Field:
                align         : left
                value         : FXN
                width         : 28
              PostScript::Report::Field:
                align         : right
                value         : PostScript::Report::Value::Constant
                  value         : AP
                width         : 17
              PostScript::Report::Checkbox:
                padding_bottom: 3
                value         : AP
                width         : 20
              PostScript::Report::Field:
                align         : right
                value         : PostScript::Report::Value::Constant
                  value         : BP
                width         : 20
              PostScript::Report::Checkbox:
                padding_bottom: 3
                value         : BP
                width         : 20
              PostScript::Report::Field:
                align         : right
                value         : PostScript::Report::Value::Constant
                  value         : Photo
                width         : 45
              PostScript::Report::Field:
                align         : left
                value         : photo
                width         : 28
              PostScript::Report::Field:
                align         : right
                value         : PostScript::Report::Value::Constant
                  value         : QTY
                width         : 35
              PostScript::Report::Field:
                align         : left
                value         : qty
                width         : 27
---
%!PS-Adobe-3.0
%%Orientation: Landscape
%%DocumentNeededResources:
%%+ font Courier-Bold Helvetica Helvetica-Bold
%%DocumentSuppliedResources:
%%+ procset PostScript__Report 0.05 0
%%+ procset PostScript__Report__Checkbox 0.01 0
%%+ procset PostScript__Report__Field 0.05 0
%%+ procset PostScript__Report__FieldTL 0.05 0
%%Title: (Report)
%%Pages: 2
%%PageOrder: Ascend
%%EndComments
%%BeginProlog
%%BeginResource: procset PostScript__Report 0.05 0
/boxpath
{
newpath
2 copy moveto                 % move to BR
3 index exch lineto	        % line to BL
1 index
4 2 roll
lineto                        % line to TL
lineto                        % line to TR
closepath
} bind def
/clipbox { boxpath clip } bind def
/drawbox { boxpath stroke } bind def
/db0 { 5 { pop } repeat } bind def
/db1 { gsave setlinewidth drawbox grestore } bind def
/boxLT { 3 index  3 index } bind def
/boxRT { 1 index  3 index } bind def
/boxLB { 3 index  1 index } bind def
/boxRB { 2 copy           } bind def
/bdrB { gsave setlinewidth } bind def
/bdrE {
lineto stroke			% Finish the line and stroke it
pop pop pop pop		% Remove L T R B
grestore
} bind def
/dbT { bdrB  boxLT moveto  boxRT bdrE } bind def
/dbB { bdrB  boxLB moveto  boxRB bdrE } bind def
/dbL { bdrB  boxLT moveto  boxLB bdrE } bind def
/dbR { bdrB  boxRT moveto  boxRB bdrE } bind def
/dbTB { 5 copy  dbT dbB } bind def
/dbLR { 5 copy  dbL dbR } bind def
/dbTL { bdrB  boxRT moveto  boxLT lineto  boxLB bdrE } bind def
/dbTR { bdrB  boxLT moveto  boxRT lineto  boxRB bdrE } bind def
/dbBL { bdrB  boxRB moveto  boxLB lineto  boxLT bdrE } bind def
/dbBR { bdrB  boxLB moveto  boxRB lineto  boxRT bdrE } bind def
/dbTLR { bdrB  boxLB moveto  boxLT lineto  boxRT lineto  boxRB bdrE } bind def
/dbBLR { bdrB  boxLT moveto  boxLB lineto  boxRB lineto  boxRT bdrE } bind def
/dbTBL { bdrB  boxRT moveto  boxLT lineto  boxLB lineto  boxRB bdrE } bind def
/dbTBR { bdrB  boxLT moveto  boxRT lineto  boxRB lineto  boxLB bdrE } bind def
/setColor
{
dup type (arraytype) eq {
aload pop
setrgbcolor
}{
setgray
} ifelse
} bind def
/fillbox
{
gsave
setColor
boxpath
fill
grestore
} bind def
/showcenter
{
newpath
0 0 moveto
dup 4 1 roll                          % Put a copy of STRING on bottom
false charpath flattenpath pathbbox   % Compute bounding box of STRING
pop exch pop                          % Discard Y values (... Lx Ux)
add 2 div neg                         % Compute X offset
0                                     % Use 0 for y offset
newpath
moveto
rmoveto
show
} bind def
/showleft
{
newpath
3 1 roll  % STRING X Y
moveto
show
} bind def
/showright
{
newpath
0 0 moveto
dup 4 1 roll                          % Put a copy of STRING on bottom
false charpath flattenpath pathbbox   % Compute bounding box of STRING
pop exch pop                          % Discard Y values (... Lx Ux)
add neg                               % Compute X offset
0                                     % Use 0 for y offset
newpath
moveto
rmoveto
show
} bind def
%%EndResource
%%BeginResource: procset PostScript__Report__Checkbox 0.01 0
/Checkbox
{
gsave
setlinewidth
translate			% SIZE VALUE
0  2 index			% SIZE VALUE L T
dup  0			% SIZE VALUE L T R B
drawbox			% SIZE VALUE
{				% SIZE
600 div  dup  scale		% stack empty
newpath
75 257 moveto
219 90 lineto
292 240 382 377 526 508 curveto
418 447 299 331 197 188 curveto
closepath
fill
}
{ pop } ifelse
grestore
} bind def
%%EndResource
%%BeginResource: procset PostScript__Report__Field 0.05 0
/Field { gsave  4 copy  clipbox  8 4 roll setfont } bind def
/Field-C { Field showcenter grestore } bind def
/Field-L { Field showleft   grestore } bind def
/Field-R { Field showright  grestore } bind def
%%EndResource
%%BeginResource: procset PostScript__Report__FieldTL 0.05 0
/FieldTL
{
gsave
setfont
4 copy clipbox	% C... Csp Cx Cy FUNC LINES CF LABEL Lx Ly L T R B
3 index		% C... Csp Cx Cy FUNC LINES CF LABEL Lx Ly L T R B L
7 -1 roll add		% C... Csp Cx Cy FUNC LINES CF LABEL Ly L T R B LblX
3 index		% C... Csp Cx Cy FUNC LINES CF LABEL Ly L T R B LblX T
7 -1 roll sub		% C... Csp Cx Cy FUNC LINES CF LABEL L T R B LblX LblY
7 -1 roll showleft	% C... Csp Cx Cy FUNC LINES CF L T R B
5 -1 roll setfont	% C... Csp Cx Cy FUNC LINES L T R B
2 index		% C... Csp Cx Cy FUNC LINES L T R B T
8 -1 roll sub		% C... Csp Cx FUNC LINES L T R B Ypos
4 index		% C... Csp Cx FUNC LINES L T R B Ypos L
3 index		% C... Csp Cx FUNC LINES L T R B Ypos L R
3 -1 roll		% C... Csp Cx FUNC LINES L T R B L R Ypos
8 -1 roll		% C... Csp Cx FUNC L T R B L R Ypos LINES
{			% C... Csp Cx FUNC L T R B L R Ypos
3 copy		% C... Csp Cx FUNC L T R B L R Ypos L R Ypos
14 -1 roll		% C... Csp Cx FUNC L T R B L R Ypos L R Ypos CONTENT
4 2 roll		% C... Csp Cx FUNC L T R B L R Ypos Ypos CONTENT L R
12 index		% C... Csp Cx FUNC L T R B L R Ypos Ypos CONTENT L R Cx
12 index cvx exec	% C... Csp Cx FUNC L T R B L R Ypos
9 index sub		% C... Csp Cx FUNC L T R B L R YposNext
} repeat
pop pop pop		% Csp Cx FUNC L T R B
7 -3 roll		% L T R B Csp Cx FUNC
pop pop pop		% L T R B
grestore
} def
/FieldTL-C {
pop                   % Y CONTENT L R
add 2 div             % Y CONTENT Xpos
3 1 roll              % Xpos Y CONTENT
showcenter
} def
/FieldTL-L {
exch pop add		% Y CONTENT Xpos
3 1 roll              % Xpos Y CONTENT
showleft
} def
/FieldTL-R {
sub exch pop		% Y CONTENT Xpos
3 1 roll              % Xpos Y CONTENT
showright
} def
%%EndResource
%%EndProlog
%%BeginSetup
/fnA /Helvetica-Bold-iso findfont 9 scalefont def
/fnB /Helvetica-Bold-iso findfont 8 scalefont def
/fnC /Helvetica-iso findfont 9 scalefont def
/fnD /Helvetica-iso findfont 8 scalefont def
/fnE /Helvetica-iso findfont 6 scalefont def
%%EndSetup
%%Page: 1 1
%%PageBoundingBox: 25 20 587 772
%%BeginPageSetup
/pagelevel save def
landscape
userdict begin
%%EndPageSetup
20 579
(AIRPLANE COMPONENT FIXING INC.)
fnA 20 587 220 575 Field-L 0.5 db0
395.5 579
(WORK ORDER)
fnA 220 587 571 575 Field-C 0.5 db0
771 579
(F.A.A REPAIR STATION NO. L3PF428Q)
fnA 571 587 771 575 Field-R 0.5 db0
(IMAGINARY AIRWAYS)
9 3 15 /FieldTL-C 1 fnC
(Customer Name:)
3 6 20 575 180 553 fnE FieldTL 0.5 db1
(957X1427-3)
9 3 15 /FieldTL-C 1 fnC
(Part Number Received:)
3 6 180 575 326 553 fnE FieldTL 0.5 db1
(-45)
9 3 15 /FieldTL-C 1 fnC
(Serial Number Received:)
3 6 326 575 482 553 fnE FieldTL 0.5 db1
(797)
9 3 15 /FieldTL-L 1 fnC
(Installed On:)
3 6 482 575 612 553 fnE FieldTL 0.5 db1
(A1)
9 3 15 /FieldTL-C 1 fnC
(Location:)
3 6 612 575 666 553 fnE FieldTL 0.5 db1
(68452-8)
9 3 15 /FieldTL-C 1 fnA
(Work Order#:)
3 6 666 575 771 553 fnE FieldTL 0.5 db1
20 575 771 553 0.5 db1
(TURBOFAN)
9 3 15 /FieldTL-C 1 fnC
(Part Description:)
3 6 20 553 180 531 fnE FieldTL 0.5 db1
(957X1427-3)
9 3 15 /FieldTL-C 1 fnC
(Part Number Returned:)
3 6 180 553 326 531 fnE FieldTL 0.5 db1
(N/A)
9 3 15 /FieldTL-C 1 fnC
(Serial Number Returned:)
3 6 326 553 482 531 fnE FieldTL 0.5 db1
20 553 482 531 0.5 db1
(05/06/2009)
9 3 15 /FieldTL-C 1 fnC
(Date Received:)
3 6 20 531 89 509 fnE FieldTL 0.5 db1
(05/06/2009)
9 3 15 /FieldTL-C 1 fnC
(RO Due Date:)
3 6 89 531 180 509 fnE FieldTL 0.5 db1
(REPAIR PER B797 CMM 47-42-96 REV 40 DATED 07MAY2009)
9 3 15 /FieldTL-L 1 fnC
(Repair/Overhaul Per:)
3 6 180 531 482 509 fnE FieldTL 0.5 db1
20 531 482 509 0.5 db1
20 553 482 509 0.5 db1
(WRAP NOW)
(MORE WORDS TO MAKE IT)
(FOO BAR 123 AND SOME)
9 3 15 /FieldTL-L 3 fnC
(Material Type:)
3 6 482 553 612 509 fnE FieldTL 0.5 db1
(8452647)
9 3 15 /FieldTL-C 1 fnC
(Customer Order Number:)
3 6 612 553 771 531 fnE FieldTL 0.5 db1
(951)
9 3 15 /FieldTL-C 1 fnC
(Part Verified By:)
3 6 612 531 692 509 fnE FieldTL 0.5 db1
()
9 3 15 /FieldTL-C 1 fnC
(Revised Due Date:)
3 6 692 531 771 509 fnE FieldTL 0.5 db1
612 531 771 509 0.5 db1
612 553 771 509 0.5 db1
20 553 771 509 0.5 db1
34.5 496
(SEQ#)
fnA 20 509 49 490 Field-C 0.5 db1
69 496
(STA#)
fnA 49 509 89 490 Field-C 0.5 db1
92 496
(REPAIR SCOPE)
fnA 89 509 539 490 Field-L 0.5 db1
575.5 496
(MECHANIC)
fnA 539 509 612 490 Field-C 0.5 db1
652 496
(INSPECTOR)
fnA 612 509 692 490 Field-C 0.5 db1
731.5 496
(DATE)
fnA 692 509 771 490 Field-C 0.5 db1
20 509 771 490 0.5 db1
20 575 771 490 0.5 db1
20 490 771 471 1 fillbox
34.5 477
(1)
fnC 20 490 49 471 Field-C 0.5 db1
69 477
(I1)
fnC 49 490 89 471 Field-C 0.5 db1
92 477
(INSPECT, PN & SN VERIFIED)
fnC 89 490 539 471 Field-L 0.5 db1
575.5 477
(XXXXXXXX)
fnC 539 490 612 471 Field-C 0.5 db1
652 477
()
fnC 612 490 692 471 Field-C 0.5 db1
692 490 771 471 0.5 db1
20 490 771 471 0.5 db1
20 471 771 452 [ 1 0.667 0.267 ] fillbox
34.5 458
(2)
fnC 20 471 49 452 Field-C 0.5 db1
69 458
(I1)
fnC 49 471 89 452 Field-C 0.5 db1
92 458
(ADDITIONAL DATA USED: BOEING ASSEMBLY DRAWING 589X1674, GDR9726)
fnC 89 471 539 452 Field-L 0.5 db1
575.5 458
(XXXXXXXX)
fnC 539 471 612 452 Field-C 0.5 db1
652 458
()
fnC 612 471 692 452 Field-C 0.5 db1
692 471 771 452 0.5 db1
20 471 771 452 0.5 db1
20 452 771 433 1 fillbox
34.5 439
(3)
fnC 20 452 49 433 Field-C 0.5 db1
69 439
(I1)
fnC 49 452 89 433 Field-C 0.5 db1
92 439
(�Fourscore and seven years ago our fathers brought forth on this)
fnC 89 452 539 433 Field-L 0.5 db1
575.5 439
(XXXXXXXX)
fnC 539 452 612 433 Field-C 0.5 db1
652 439
()
fnC 612 452 692 433 Field-C 0.5 db1
692 452 771 433 0.5 db1
20 452 771 433 0.5 db1
20 433 771 414 [ 1 0.667 0.267 ] fillbox
34.5 420
(4)
fnC 20 433 49 414 Field-C 0.5 db1
69 420
(I1)
fnC 49 433 89 414 Field-C 0.5 db1
92 420
(continent a new nation, conceived in liberty and dedicated to the )
fnC 89 433 539 414 Field-L 0.5 db1
575.5 420
(XXXXXXXX)
fnC 539 433 612 414 Field-C 0.5 db1
652 420
()
fnC 612 433 692 414 Field-C 0.5 db1
692 433 771 414 0.5 db1
20 433 771 414 0.5 db1
20 414 771 395 1 fillbox
34.5 401
(5)
fnC 20 414 49 395 Field-C 0.5 db1
69 401
(I1)
fnC 49 414 89 395 Field-C 0.5 db1
92 401
(proposition that all men are created equal. Now we are engaged in )
fnC 89 414 539 395 Field-L 0.5 db1
575.5 401
(XXXXXXXX)
fnC 539 414 612 395 Field-C 0.5 db1
652 401
()
fnC 612 414 692 395 Field-C 0.5 db1
692 414 771 395 0.5 db1
20 414 771 395 0.5 db1
20 395 771 376 [ 1 0.667 0.267 ] fillbox
34.5 382
(6)
fnC 20 395 49 376 Field-C 0.5 db1
69 382
(I1)
fnC 49 395 89 376 Field-C 0.5 db1
92 382
(a great civil war, testing whether that nation or any nation so )
fnC 89 395 539 376 Field-L 0.5 db1
575.5 382
(XXXXXXXX)
fnC 539 395 612 376 Field-C 0.5 db1
652 382
()
fnC 612 395 692 376 Field-C 0.5 db1
692 395 771 376 0.5 db1
20 395 771 376 0.5 db1
20 376 771 357 1 fillbox
34.5 363
(7)
fnC 20 376 49 357 Field-C 0.5 db1
69 363
(I1)
fnC 49 376 89 357 Field-C 0.5 db1
92 363
(conceived and so dedicated can long endure. We are met on a great )
fnC 89 376 539 357 Field-L 0.5 db1
575.5 363
(XXXXXXXX)
fnC 539 376 612 357 Field-C 0.5 db1
652 363
()
fnC 612 376 692 357 Field-C 0.5 db1
692 376 771 357 0.5 db1
20 376 771 357 0.5 db1
20 357 771 338 [ 1 0.667 0.267 ] fillbox
34.5 344
(8)
fnC 20 357 49 338 Field-C 0.5 db1
69 344
(S1)
fnC 49 357 89 338 Field-C 0.5 db1
92 344
(battlefield of that war. We have come to dedicate a portion of )
fnC 89 357 539 338 Field-L 0.5 db1
575.5 344
()
fnC 539 357 612 338 Field-C 0.5 db1
652 344
(XXXXXXXX)
fnC 612 357 692 338 Field-C 0.5 db1
692 357 771 338 0.5 db1
20 357 771 338 0.5 db1
20 338 771 319 1 fillbox
34.5 325
(9)
fnC 20 338 49 319 Field-C 0.5 db1
69 325
(W1)
fnC 49 338 89 319 Field-C 0.5 db1
92 325
(that field as a final resting�place for those who here gave their )
fnC 89 338 539 319 Field-L 0.5 db1
575.5 325
()
fnC 539 338 612 319 Field-C 0.5 db1
652 325
()
fnC 612 338 692 319 Field-C 0.5 db1
692 338 771 319 0.5 db1
20 338 771 319 0.5 db1
20 319 771 300 [ 1 0.667 0.267 ] fillbox
34.5 306
(10)
fnC 20 319 49 300 Field-C 0.5 db1
69 306
(W1)
fnC 49 319 89 300 Field-C 0.5 db1
92 306
(lives that that nation might live. It is altogether fitting and )
fnC 89 319 539 300 Field-L 0.5 db1
575.5 306
()
fnC 539 319 612 300 Field-C 0.5 db1
652 306
(XXXXXXXX)
fnC 612 319 692 300 Field-C 0.5 db1
692 319 771 300 0.5 db1
20 319 771 300 0.5 db1
20 300 771 281 1 fillbox
34.5 287
(11)
fnC 20 300 49 281 Field-C 0.5 db1
69 287
(W1)
fnC 49 300 89 281 Field-C 0.5 db1
92 287
(proper that we should do this. But in a larger sense, we cannot )
fnC 89 300 539 281 Field-L 0.5 db1
575.5 287
()
fnC 539 300 612 281 Field-C 0.5 db1
652 287
(XXXXXXXX)
fnC 612 300 692 281 Field-C 0.5 db1
692 300 771 281 0.5 db1
20 300 771 281 0.5 db1
20 281 771 262 [ 1 0.667 0.267 ] fillbox
34.5 268
(12)
fnC 20 281 49 262 Field-C 0.5 db1
69 268
(W1)
fnC 49 281 89 262 Field-C 0.5 db1
92 268
(dedicate, we cannot consecrate, we cannot hallow this ground. )
fnC 89 281 539 262 Field-L 0.5 db1
575.5 268
()
fnC 539 281 612 262 Field-C 0.5 db1
652 268
(XXXXXXXX)
fnC 612 281 692 262 Field-C 0.5 db1
692 281 771 262 0.5 db1
20 281 771 262 0.5 db1
20 262 771 243 1 fillbox
34.5 249
(13)
fnC 20 262 49 243 Field-C 0.5 db1
69 249
(W1)
fnC 49 262 89 243 Field-C 0.5 db1
92 249
(The brave men, living and dead who struggled here have consecrated )
fnC 89 262 539 243 Field-L 0.5 db1
575.5 249
()
fnC 539 262 612 243 Field-C 0.5 db1
652 249
(XXXXXXXX)
fnC 612 262 692 243 Field-C 0.5 db1
692 262 771 243 0.5 db1
20 262 771 243 0.5 db1
20 243 771 224 [ 1 0.667 0.267 ] fillbox
34.5 230
(14)
fnC 20 243 49 224 Field-C 0.5 db1
69 230
(W1)
fnC 49 243 89 224 Field-C 0.5 db1
92 230
(it far above our poor power to add or detract. The world will )
fnC 89 243 539 224 Field-L 0.5 db1
575.5 230
()
fnC 539 243 612 224 Field-C 0.5 db1
652 230
(XXXXXXXX)
fnC 612 243 692 224 Field-C 0.5 db1
692 243 771 224 0.5 db1
20 243 771 224 0.5 db1
20 224 771 205 1 fillbox
34.5 211
(15)
fnC 20 224 49 205 Field-C 0.5 db1
69 211
(W1)
fnC 49 224 89 205 Field-C 0.5 db1
92 211
(little note nor long remember what we say here, but it can never )
fnC 89 224 539 205 Field-L 0.5 db1
575.5 211
()
fnC 539 224 612 205 Field-C 0.5 db1
652 211
()
fnC 612 224 692 205 Field-C 0.5 db1
692 224 771 205 0.5 db1
20 224 771 205 0.5 db1
20 205 771 186 [ 1 0.667 0.267 ] fillbox
34.5 192
(16)
fnC 20 205 49 186 Field-C 0.5 db1
69 192
(P1)
fnC 49 205 89 186 Field-C 0.5 db1
92 192
(forget what they did here. It is for us the living rather to be )
fnC 89 205 539 186 Field-L 0.5 db1
575.5 192
()
fnC 539 205 612 186 Field-C 0.5 db1
652 192
(XXXXXXXX)
fnC 612 205 692 186 Field-C 0.5 db1
692 205 771 186 0.5 db1
20 205 771 186 0.5 db1
20 186 771 167 1 fillbox
34.5 173
(17)
fnC 20 186 49 167 Field-C 0.5 db1
69 173
(P1)
fnC 49 186 89 167 Field-C 0.5 db1
92 173
(dedicated here to the unfinished work which they who fought here )
fnC 89 186 539 167 Field-L 0.5 db1
575.5 173
()
fnC 539 186 612 167 Field-C 0.5 db1
652 173
(XXXXXXXX)
fnC 612 186 692 167 Field-C 0.5 db1
692 186 771 167 0.5 db1
20 186 771 167 0.5 db1
20 167 771 148 [ 1 0.667 0.267 ] fillbox
34.5 154
(18)
fnC 20 167 49 148 Field-C 0.5 db1
69 154
(P1)
fnC 49 167 89 148 Field-C 0.5 db1
92 154
(have thus far so nobly advanced. It is rather for us to be here )
fnC 89 167 539 148 Field-L 0.5 db1
575.5 154
()
fnC 539 167 612 148 Field-C 0.5 db1
652 154
(XXXXXXXX)
fnC 612 167 692 148 Field-C 0.5 db1
692 167 771 148 0.5 db1
20 167 771 148 0.5 db1
20 148 771 129 1 fillbox
34.5 135
(19)
fnC 20 148 49 129 Field-C 0.5 db1
69 135
(P1)
fnC 49 148 89 129 Field-C 0.5 db1
92 135
(dedicated to the great task remaining before us�that from these )
fnC 89 148 539 129 Field-L 0.5 db1
575.5 135
()
fnC 539 148 612 129 Field-C 0.5 db1
652 135
()
fnC 612 148 692 129 Field-C 0.5 db1
692 148 771 129 0.5 db1
20 148 771 129 0.5 db1
20 129 771 110 [ 1 0.667 0.267 ] fillbox
34.5 116
(20)
fnC 20 129 49 110 Field-C 0.5 db1
69 116
(P1)
fnC 49 129 89 110 Field-C 0.5 db1
92 116
(honored dead we take increased devotion to that cause for which )
fnC 89 129 539 110 Field-L 0.5 db1
575.5 116
()
fnC 539 129 612 110 Field-C 0.5 db1
652 116
()
fnC 612 129 692 110 Field-C 0.5 db1
692 129 771 110 0.5 db1
20 129 771 110 0.5 db1
20 110 771 91 1 fillbox
34.5 97
(21)
fnC 20 110 49 91 Field-C 0.5 db1
69 97
(F1)
fnC 49 110 89 91 Field-C 0.5 db1
92 97
(they gave the last full measure of devotion�that we here highly)
fnC 89 110 539 91 Field-L 0.5 db1
575.5 97
(XXXXXXXX)
fnC 539 110 612 91 Field-C 0.5 db1
652 97
()
fnC 612 110 692 91 Field-C 0.5 db1
692 110 771 91 0.5 db1
20 110 771 91 0.5 db1
395.5 65
(The component identified above was repaired/overhauled/inspected IAW current federal aviation regulations and in respect to that work, was found airworthy for return to service.)
fnB 20 83 771 61 Field-C 0.5 db0
()
9 3 15 /FieldTL-C 1 fnC
(Inspector)
3 6 20 61 359 39 fnE FieldTL 0.5 db1
()
9 3 15 /FieldTL-C 1 fnC
(Final Inspection Stamp)
3 6 359 61 513 39 fnE FieldTL 0.5 db1
()
9 3 15 /FieldTL-C 1 fnC
(Date)
3 6 513 61 771 39 fnE FieldTL 0.5 db1
20 61 771 39 0.5 db1
48.5 29
(42410-1)
fnD 20 39 77 25 Field-C 0.5 db0
91 29
(Page\(s\): 1 OF 2)
fnD 91 39 468 25 Field-L 0.5 db0
476 31
(ML)
fnE 468 39 478 25 Field-R 0.5 db0
529 31
(FXN�)
fnE 478 39 531 25 Field-R 0.5 db0
533 31
(0)
fnE 531 39 559 25 Field-L 0.5 db0
574 31
(AP)
fnE 559 39 576 25 Field-R 0.5 db0
8 false 582 28 0.5 Checkbox
614 31
(BP)
fnE 596 39 616 25 Field-R 0.5 db0
8 true 622 28 0.5 Checkbox
679 31
(Photo)
fnE 636 39 681 25 Field-R 0.5 db0
683 31
(6)
fnE 681 39 709 25 Field-L 0.5 db0
742 31
(QTY)
fnE 709 39 744 25 Field-R 0.5 db0
746 31
(1)
fnE 744 39 771 25 Field-L 0.5 db0
20 39 771 25 0.5 db1
%%PageTrailer
end
pagelevel restore
showpage
%%Page: 2 2
%%PageBoundingBox: 25 20 587 772
%%BeginPageSetup
/pagelevel save def
landscape
userdict begin
%%EndPageSetup
(IMAGINARY AIRWAYS)
9 3 15 /FieldTL-C 1 fnC
(Customer Name:)
3 6 20 587 180 565 fnE FieldTL 0.5 db1
(957X1427-3)
9 3 15 /FieldTL-C 1 fnC
(Part Number Received:)
3 6 180 587 326 565 fnE FieldTL 0.5 db1
(-45)
9 3 15 /FieldTL-C 1 fnC
(Serial Number Received:)
3 6 326 587 482 565 fnE FieldTL 0.5 db1
(797)
9 3 15 /FieldTL-L 1 fnC
(Installed On:)
3 6 482 587 612 565 fnE FieldTL 0.5 db1
(A1)
9 3 15 /FieldTL-C 1 fnC
(Location:)
3 6 612 587 666 565 fnE FieldTL 0.5 db1
(68452-8)
9 3 15 /FieldTL-C 1 fnA
(Work Order#:)
3 6 666 587 771 565 fnE FieldTL 0.5 db1
20 587 771 565 0.5 db1
(TURBOFAN)
9 3 15 /FieldTL-C 1 fnC
(Part Description:)
3 6 20 565 180 543 fnE FieldTL 0.5 db1
(957X1427-3)
9 3 15 /FieldTL-C 1 fnC
(Part Number Returned:)
3 6 180 565 326 543 fnE FieldTL 0.5 db1
(N/A)
9 3 15 /FieldTL-C 1 fnC
(Serial Number Returned:)
3 6 326 565 482 543 fnE FieldTL 0.5 db1
20 565 482 543 0.5 db1
(05/06/2009)
9 3 15 /FieldTL-C 1 fnC
(Date Received:)
3 6 20 543 89 521 fnE FieldTL 0.5 db1
(05/06/2009)
9 3 15 /FieldTL-C 1 fnC
(RO Due Date:)
3 6 89 543 180 521 fnE FieldTL 0.5 db1
(REPAIR PER B797 CMM 47-42-96 REV 40 DATED 07MAY2009)
9 3 15 /FieldTL-L 1 fnC
(Repair/Overhaul Per:)
3 6 180 543 482 521 fnE FieldTL 0.5 db1
20 543 482 521 0.5 db1
20 565 482 521 0.5 db1
(WRAP NOW)
(MORE WORDS TO MAKE IT)
(FOO BAR 123 AND SOME)
9 3 15 /FieldTL-L 3 fnC
(Material Type:)
3 6 482 565 612 521 fnE FieldTL 0.5 db1
(8452647)
9 3 15 /FieldTL-C 1 fnC
(Customer Order Number:)
3 6 612 565 771 543 fnE FieldTL 0.5 db1
(951)
9 3 15 /FieldTL-C 1 fnC
(Part Verified By:)
3 6 612 543 692 521 fnE FieldTL 0.5 db1
()
9 3 15 /FieldTL-C 1 fnC
(Revised Due Date:)
3 6 692 543 771 521 fnE FieldTL 0.5 db1
612 543 771 521 0.5 db1
612 565 771 521 0.5 db1
20 565 771 521 0.5 db1
34.5 508
(SEQ#)
fnA 20 521 49 502 Field-C 0.5 db1
69 508
(STA#)
fnA 49 521 89 502 Field-C 0.5 db1
92 508
(REPAIR SCOPE)
fnA 89 521 539 502 Field-L 0.5 db1
575.5 508
(MECHANIC)
fnA 539 521 612 502 Field-C 0.5 db1
652 508
(INSPECTOR)
fnA 612 521 692 502 Field-C 0.5 db1
731.5 508
(DATE)
fnA 692 521 771 502 Field-C 0.5 db1
20 521 771 502 0.5 db1
20 587 771 502 0.5 db1
20 502 771 483 [ 1 0.667 0.267 ] fillbox
34.5 489
(22)
fnC 20 502 49 483 Field-C 0.5 db1
69 489
(P1)
fnC 49 502 89 483 Field-C 0.5 db1
92 489
(resolve that these dead shall not have died in vain, that this )
fnC 89 502 539 483 Field-L 0.5 db1
575.5 489
()
fnC 539 502 612 483 Field-C 0.5 db1
652 489
(XXXXXXXX)
fnC 612 502 692 483 Field-C 0.5 db1
692 502 771 483 0.5 db1
20 502 771 483 0.5 db1
20 483 771 464 1 fillbox
34.5 470
(23)
fnC 20 483 49 464 Field-C 0.5 db1
69 470
(P1)
fnC 49 483 89 464 Field-C 0.5 db1
92 470
(nation under God shall have a new birth of freedom, and that )
fnC 89 483 539 464 Field-L 0.5 db1
575.5 470
()
fnC 539 483 612 464 Field-C 0.5 db1
652 470
(XXXXXXXX)
fnC 612 483 692 464 Field-C 0.5 db1
692 483 771 464 0.5 db1
20 483 771 464 0.5 db1
20 464 771 445 [ 1 0.667 0.267 ] fillbox
34.5 451
(24)
fnC 20 464 49 445 Field-C 0.5 db1
69 451
(S1)
fnC 49 464 89 445 Field-C 0.5 db1
92 451
(government of the people, by the people, for the people shall )
fnC 89 464 539 445 Field-L 0.5 db1
575.5 451
()
fnC 539 464 612 445 Field-C 0.5 db1
652 451
(XXXXXXXX)
fnC 612 464 692 445 Field-C 0.5 db1
692 464 771 445 0.5 db1
20 464 771 445 0.5 db1
20 445 771 426 1 fillbox
34.5 432
(25)
fnC 20 445 49 426 Field-C 0.5 db1
69 432
(SR)
fnC 49 445 89 426 Field-C 0.5 db1
92 432
(not perish from the earth.�)
fnC 89 445 539 426 Field-L 0.5 db1
575.5 432
()
fnC 539 445 612 426 Field-C 0.5 db1
652 432
(XXXXXXXX)
fnC 612 445 692 426 Field-C 0.5 db1
692 445 771 426 0.5 db1
20 445 771 426 0.5 db1
20 426 771 407 [ 1 0.667 0.267 ] fillbox
34.5 413
(26)
fnC 20 426 49 407 Field-C 0.5 db1
69 413
(I1)
fnC 49 426 89 407 Field-C 0.5 db1
92 413
(�Abraham Lincoln)
fnC 89 426 539 407 Field-L 0.5 db1
575.5 413
(XXXXXXXX)
fnC 539 426 612 407 Field-C 0.5 db1
652 413
()
fnC 612 426 692 407 Field-C 0.5 db1
692 426 771 407 0.5 db1
20 426 771 407 0.5 db1
395.5 65
(The component identified above was repaired/overhauled/inspected IAW current federal aviation regulations and in respect to that work, was found airworthy for return to service.)
fnB 20 83 771 61 Field-C 0.5 db0
()
9 3 15 /FieldTL-C 1 fnC
(Inspector)
3 6 20 61 359 39 fnE FieldTL 0.5 db1
()
9 3 15 /FieldTL-C 1 fnC
(Final Inspection Stamp)
3 6 359 61 513 39 fnE FieldTL 0.5 db1
()
9 3 15 /FieldTL-C 1 fnC
(Date)
3 6 513 61 771 39 fnE FieldTL 0.5 db1
20 61 771 39 0.5 db1
48.5 29
(42410-1)
fnD 20 39 77 25 Field-C 0.5 db0
91 29
(Page\(s\): 2 OF 2)
fnD 91 39 468 25 Field-L 0.5 db0
476 31
(ML)
fnE 468 39 478 25 Field-R 0.5 db0
529 31
(FXN�)
fnE 478 39 531 25 Field-R 0.5 db0
533 31
(0)
fnE 531 39 559 25 Field-L 0.5 db0
574 31
(AP)
fnE 559 39 576 25 Field-R 0.5 db0
8 false 582 28 0.5 Checkbox
614 31
(BP)
fnE 596 39 616 25 Field-R 0.5 db0
8 true 622 28 0.5 Checkbox
679 31
(Photo)
fnE 636 39 681 25 Field-R 0.5 db0
683 31
(6)
fnE 681 39 709 25 Field-L 0.5 db0
742 31
(QTY)
fnE 709 39 744 25 Field-R 0.5 db0
746 31
(1)
fnE 744 39 771 25 Field-L 0.5 db0
20 39 771 25 0.5 db1
%%PageTrailer
end
pagelevel restore
showpage
%%EOF
---
align         : center
border        : 1
font          : Helvetica-iso 9
label_font    : Helvetica-iso 6
line_width    : 0.5
padding_bottom: 4
padding_side  : 3
row_height    : 22

report_header:
  PostScript::Report::HBox:
    border        : 0
    font          : Helvetica-Bold-iso 9
    height        : 12
    padding_side  : 0
    width         : 751
    children:
      PostScript::Report::Field:
        align         : left
        value         : PostScript::Report::Value::Constant
          value         : AIRPLANE COMPONENT FIXING INC.
        width         : 200
      PostScript::Report::Field:
        value         : PostScript::Report::Value::Constant
          value         : WORK ORDER
        width         : 351
      PostScript::Report::Field:
        align         : right
        value         : PostScript::Report::Value::Constant
          value         : F.A.A REPAIR STATION NO. L3PF428Q
        width         : 200

page_header:
  PostScript::Report::VBox:
    height        : 85
    width         : 751
    children:
      PostScript::Report::HBox:
        height        : 22
        width         : 751
        children:
          PostScript::Report::FieldTL:
            label         : Customer Name:
            value         : custName
            width         : 160
          PostScript::Report::FieldTL:
            label         : Part Number Received:
            value         : partNumReceived
            width         : 146
          PostScript::Report::FieldTL:
            label         : Serial Number Received:
            value         : serialNumReceived
            width         : 156
          PostScript::Report::FieldTL:
            align         : left
            label         : Installed On:
            value         : installedOn
            width         : 130
          PostScript::Report::FieldTL:
            label         : Location:
            value         : location
            width         : 54
          PostScript::Report::FieldTL:
            font          : Helvetica-Bold-iso 9
            label         : Work Order#:
            value         : workOrder
            width         : 105
      PostScript::Report::HBox:
        height        : 44
        width         : 751
        children:
          PostScript::Report::VBox:
            height        : 44
            width         : 462
            children:
              PostScript::Report::HBox:
                height        : 22
                width         : 462
                children:
                  PostScript::Report::FieldTL:
                    label         : Part Description:
                    value         : partDesc
                    width         : 160
                  PostScript::Report::FieldTL:
                    label         : Part Number Returned:
                    value         : partNumReturned
                    width         : 146
                  PostScript::Report::FieldTL:
                    label         : Serial Number Returned:
                    value         : serialNumReturned
                    width         : 156
              PostScript::Report::HBox:
                height        : 22
                width         : 462
                children:
                  PostScript::Report::FieldTL:
                    label         : Date Received:
                    value         : dateReceived
                    width         : 69
                  PostScript::Report::FieldTL:
                    label         : RO Due Date:
                    value         : roDueDate
                    width         : 91
                  PostScript::Report::FieldTL:
                    align         : left
                    label         : Repair/Overhaul Per:
                    value         : repairPer
                    width         : 302
          PostScript::Report::FieldTL:
            align         : left
            height        : 44
            label         : Material Type:
            multiline     : 1
            value         : materialType
            width         : 130
          PostScript::Report::VBox:
            height        : 44
            width         : 159
            children:
              PostScript::Report::FieldTL:
                height        : 22
                label         : Customer Order Number:
                value         : custOrderNum
                width         : 159
              PostScript::Report::HBox:
                height        : 22
                width         : 159
                children:
                  PostScript::Report::FieldTL:
                    label         : Part Verified By:
                    value         : verifiedBy
                    width         : 80
                  PostScript::Report::FieldTL:
                    label         : Revised Due Date:
                    value         : revisedDueDate
                    width         : 79
      PostScript::Report::HBox:
        font          : Helvetica-Bold-iso 9
        height        : 19
        padding_bottom: 6
        width         : 751
        children:
          PostScript::Report::Field:
            value         : PostScript::Report::Value::Constant
              value         : SEQ#
            width         : 29
          PostScript::Report::Field:
            value         : PostScript::Report::Value::Constant
              value         : STA#
            width         : 40
          PostScript::Report::Field:
            align         : left
            value         : PostScript::Report::Value::Constant
              value         : REPAIR SCOPE
            width         : 450
          PostScript::Report::Field:
            value         : PostScript::Report::Value::Constant
              value         : MECHANIC
            width         : 73
          PostScript::Report::Field:
            value         : PostScript::Report::Value::Constant
              value         : INSPECTOR
            width         : 80
          PostScript::Report::Field:
            value         : PostScript::Report::Value::Constant
              value         : DATE
            width         : 79

detail:
  PostScript::Report::HBox:
    background    : #FFAA44
    height        : 19
    padding_bottom: 6
    width         : 751
    children:
      PostScript::Report::Field:
        value         : 0
        width         : 29
      PostScript::Report::Field:
        value         : 1
        width         : 40
      PostScript::Report::Field:
        align         : left
        value         : 2
        width         : 450
      PostScript::Report::Field:
        value         : 3
        width         : 73
      PostScript::Report::Field:
        value         : 4
        width         : 80
      PostScript::Report::Spacer:
        width         : 79

page_footer:
  PostScript::Report::VBox:
    border        : 0
    height        : 58
    width         : 751
    children:
      PostScript::Report::Field:
        font          : Helvetica-Bold-iso 8
        height        : 22
        value         : PostScript::Report::Value::Constant
          value         : The component identified above was repaired/overhauled/inspected IAW current federal aviation regulations and in respect to that work, was found airworthy for return to service.
      PostScript::Report::HBox:
        border        : 1
        height        : 22
        width         : 751
        children:
          PostScript::Report::FieldTL:
            label         : Inspector
            value         : PostScript::Report::Value::Constant
              value         :
            width         : 339
          PostScript::Report::FieldTL:
            label         : Final Inspection Stamp
            value         : PostScript::Report::Value::Constant
              value         :
            width         : 154
          PostScript::Report::FieldTL:
            label         : Date
            value         : PostScript::Report::Value::Constant
              value         :
            width         : 258
      PostScript::Report::HBox:
        border        : 1
        font          : Helvetica-iso 6
        height        : 14
        padding_side  : 0
        width         : 751
        children:
          PostScript::Report::HBox:
            border        : 0
            font          : Helvetica-iso 8
            width         : 448
            children:
              PostScript::Report::Field:
                value         : PostScript::Report::Value::Constant
                  value         : 42410-1
                width         : 57
              PostScript::Report::Spacer:
                width         : 14
              PostScript::Report::Field:
                align         : left
                value         : PostScript::Report::Value::Page
                  value         : Page(s): %n OF %t
                width         : 377
          PostScript::Report::HBox:
            border        : 0
            padding_bottom: 6
            padding_side  : 2
            width         : 303
            children:
              PostScript::Report::Field:
                align         : right
                value         : PostScript::Report::Value::Constant
                  value         : ML
                width         : 10
              PostScript::Report::Field:
                align         : right
                value         : PostScript::Report::Value::Constant
                  value         : FXN-
                width         : 53
              PostScript::Report::Field:
                align         : left
                value         : FXN
                width         : 28
              PostScript::Report::Field:
                align         : right
                value         : PostScript::Report::Value::Constant
                  value         : AP
                width         : 17
              PostScript::Report::Checkbox:
                padding_bottom: 3
                size          : 8
                value         : AP
                width         : 20
              PostScript::Report::Field:
                align         : right
                value         : PostScript::Report::Value::Constant
                  value         : BP
                width         : 20
              PostScript::Report::Checkbox:
                padding_bottom: 3
                size          : 8
                value         : BP
                width         : 20
              PostScript::Report::Field:
                align         : right
                value         : PostScript::Report::Value::Constant
                  value         : Photo
                width         : 45
              PostScript::Report::Field:
                align         : left
                value         : photo
                width         : 28
              PostScript::Report::Field:
                align         : right
                value         : PostScript::Report::Value::Constant
                  value         : QTY
                width         : 35
              PostScript::Report::Field:
                align         : left
                value         : qty
                width         : 27
---
