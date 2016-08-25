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
my $rj = 0; my $tc = 0;
my $all_claims=''; my $all_clp_claims;
my @docfiles;
my $ispaid = 0;
my @bprs; my $bpr; my $clphead;

##
##  read all in a string
undef $/;

opendir(DIR,".") or die "$!";
@docfiles = grep(/ERM\d+/, readdir(DIR));
closedir(DIR);
## Iterate through all the PT files.  (CVS, express scripts may begin by N..)
##

FILE:
foreach $file (@docfiles) {
  
   if (($file =~/\.csv$/)or($file=~/no-reject/)){ 
     next FILE;   # Do not process processed files.
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
  ##   $line =~ s/\n//g;

  #  NOTE :  ▲ and ↔ (or GS, RS) or something else) are the actual field-delimiters in the file.
  #  In here, we meticulously leverage them by matching the actual delimiters

  ## divide by BPRs.
  
  @bprs = split(/BPR\*I/,$line);
  
  print "SIZE BPRs is $#bprs \n";
  $head = shift(@bprs);  ## perhaps the first element is the header?
 
  $all_claims = $head;
  
  foreach $bpr (@bprs){
    
     # There might be more than 1 check in the 835
    
     ##  Each CLP (claims paid) is follow by a code- status.  4 is reject.
     ##   - the Rx  (first #)    - Whether is a 1,2 or 4. (second #)
  
     undef @clps;       ##  Flush buffers - do not carry over previous 835 data.
     undef $clp;  undef $clp_code ;
     undef $tc; undef $rj;
     undef $clphead; undef $all_clp_claims;
    
     @clps = split(/CLP\*/, $bpr);

     $clphead = shift(@clps);  ## perhaps the first element is the header?
  
     $all_clp_claims = 'BPR*I' . $clphead;
   
     foreach $clp (@clps){
  
        #$clp =~ s/\n//g;       ## removes newline characters (gets on way of pattern match)
        if($clp =~ /^(0+)/){       ## remove zeroes preceeding the RX number
           $clp = $';
        }
    
        if ($clp =~ /^(\d{7})\*(\d{1})/){ 

           $clp_code = $2;
           print "RX is $1 \n";
           if ($clp_code == 4){
              $rj++;     
              $ispaid = 0;
              # print "REJ: $1 \n"; #DETAIL $clp \n";
           }else{
              $all_clp_claims .= "CLP*$clp";
              $ispaid = 1;
           } 
           ## was this the last CLP -- We need the trailing data.  # PLB or SE?
           if ($clp =~/PLB\*/){
              $tail = $';
              $all_clp_claims .= "PLB*$tail\n" unless $ispaid;
           }elsif ($clp =~/SE\*/){
              $tail = $';
              $all_clp_claims .= "SE*$tail\n" unless $ispaid;
           }
           $tc++;
        }
        
      } ## end for each clp
      
      $all_claims .= $all_clp_claims;
       
  }  ## end foreach BPR
   
   print FOUT ($all_claims);
   print "Total Claims  $tc, \n Total Rejects $rj\n";  # prints to screen/STDOUT
  
  close (FOUT);
   
}  ##end for each DOC/FILE
  



sub print_fixed_lines{
#  breaks string in chunks of 80 chars, adds new line, prints.
#
   my $string = shift(@_);
   while ($string =~ m/(.{1,80})/gs) {
     print FOUT $1, "\n";
   }
   return;
}