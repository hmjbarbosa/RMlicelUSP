#include "RMlicelUSP.h"

/*
  PROGRAM: rm2dat
  AUTHOR: hbarbosa
  DATE: May, 2011
 */
int main (int argc, char *argv[]) 
{
  RMDataFile XX;
  FILE *fout;
  char fdat[256];
  
  if (argc<2) {
    printf("Enter a file name!\n");
    return 1;
  }
  
  for (int i=1; i<argc; i++) {
    // Open output file
    sprintf(fdat,"%s.dat",argv[i]);
    fout=fopen(fdat,"w");

    // Init, Read, Print and destroy RM data file
    Init_RMDataFile(&XX);
    profile_read(argv[i], &XX);

    profile_glue(&XX);

    profile_printf(fout, XX, 0, "# ", " ", "\t");
    Free_RMDataFile(&XX);

    // Close output file
    fclose(fout);
  }

  return 0;
}
