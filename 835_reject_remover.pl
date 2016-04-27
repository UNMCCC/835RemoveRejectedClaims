################################################################################################
##
##   835 reject remover                             Inigo San Gil, Apr 2016
##
##   Description:    A program that removes the rejects from an 835 file
#3
##          This script will output an 835 file in the original format without rejects.  
##          the file name will contain a no-rejects string
##
##   to use:  either invoke perl  835_reject_remover.pl  or double click on it
##
##   Requirements: Source Raw data files need to be in same folder as this
##   script. Source file names need to start by "PT" (can be adapted to other providers).
##
##   Desgined for Windows, but should run OK on Nix, MacOS too (untested on those environs)
##
################################################################################################

use strict;
my $file; my $outfile;
my $clp_code;
my $line; my $clp; my @clps; 
my $head; my $tail;
my $rj=0; my $tc=0;
my $all_claims='';
my @docfiles;
##
##  read all in a string
undef $/;

opendir(DIR,".") or die "$!";
@docfiles = grep(/PT\w+\s+\d+/, readdir(DIR));
closedir(DIR);
## Iterate through all the PT files.  (CVS, express scripts may begin by N..)
##
    
foreach $file (@docfiles) {
  
   if (($file =~/\.csv$/)or($file=~/no-reject/)){ 
     next;   # Do not process processed files.
   }

   ## Flush Line
   undef $line;  
   
   # Read the contents of the PT file
   open(DOC, "$file") or print("Error opening $file $!\n");
   $line = <DOC>;
   close(DOC);
   ##
   ##  let's open the output file, give it the same name, appends csv.
   $outfile = $file.'no-rejects';

   open(FOUT, ">$outfile") or die "Could not write out your no-reject file \n";

  ## Parse (extract) the contents of the file
  
  ## clean out new lines -- unix encoding.
   $line =~ s/\n//g;

#  NOTE :  ▲ and ↔ (or GS, RS) or something else) are the actual field-delimiters in the file.
#  In here, we meticulously leverage them by matching the actual delimiters

  ##  Each CLP (claims paid) is follow by a code- status.  4 is reject.
  ##   - the Rx  (first #)    - Whether is a 1,2 or 4. (second #)
  
   undef @clps;       ##  Flush buffers - do not carry over previous 835 data.
   undef $clp;  undef $clp_code ;
   undef $all_claims; undef $tc; undef $rj;
  
   @clps = split(/CLP\x{1D}/,$line);

   $head = shift(@clps);  ## perhaps the first element is the header?
  
   $all_claims = $head;
  
   foreach $clp (@clps){
  
    $clp =~ s/\n//g;       ## removes newline characters (gets on way of pattern match)
    
    if ($clp =~ /^(\d{7})\x{1D}(\d{1})/){

      $clp_code = $2;

       if ($clp_code == 4){
         $rj++;  
         
      }else{
         $all_claims .= "CLP\x{1D}$clp";
      }
       ## provision for the case where last CLP was a reject.  We need the trailing data.  # PLB or SE?
      if ($clp =~/(PLB)\x{1D}/){
         $tail = $';
         $all_claims .= "$1\x{1D}$tail\n";
         print_fixed_lines($all_claims);
      }elsif ($clp =~/\x{1E}(SE)\x{1D}/){
         print_fixed_lines($all_claims);
      }
      $tc++;
    }
    
 }
  
 print "Total Claims  $tc, \n Total Rejects $rj\n";  # prints to screen/STDOUT
  
 close (FOUT);
}

sub print_fixed_lines{
#  breaks string in chunks of 80 chars, adds new line, prints.
#
   my $string = shift(@_);
   while ($string =~ m/(.{1,80})/gs) {
     print FOUT $1, "\n";
   }
   return;
}