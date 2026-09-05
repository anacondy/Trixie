#include <stdio.h>
#include <omp.h>
int main(){ double s=0; 
#pragma omp parallel for reduction(+:s)
for(long i=0;i<100000000L;i++) s+=1.0/(i+1); printf("sum=%f threads=%d\n",s,omp_get_max_threads()); return 0;}
