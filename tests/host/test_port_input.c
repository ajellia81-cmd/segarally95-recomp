/* No ROMs: exercise normalized input endpoints, nonfinite values and release. */
#include "port_host.h"
#include "model2_rom.h"
#include <math.h>
#include <stdio.h>
static u8 analog[3], bits;static unsigned gear;
void model2_io_analog_set(u32 ch,u8 v){if(ch<3)analog[ch]=v;}
void model2_io_in0_set_mask(u8 mask,int pressed){if(pressed)bits|=mask;else bits&=~mask;}
void model2_io_shifter_set(u32 g){gear=g;}
#define CHECK(x) do {if(!(x)){fprintf(stderr,"failed: %s\n",#x);return 1;}}while(0)
int main(void){
 port_input_t p={-1,1,1,1,1,1,4};port_input_apply(&p);
 CHECK(analog[0]==0&&analog[1]==255&&analog[2]==255&&bits&&gear==4);
 p.steer=1;p.throttle=INFINITY;p.brake=NAN;p.gear=99;port_input_apply(&p);
 CHECK(analog[0]==255&&analog[1]==0&&analog[2]==0&&gear==0);
 p.steer=100;p.throttle=-1;p.brake=2;port_input_apply(&p);
 CHECK(analog[0]==255&&analog[1]==0&&analog[2]==255);
 port_input_release();CHECK(analog[0]==128&&analog[1]==0&&analog[2]==0&&!bits&&!gear);
 port_input_apply(NULL);CHECK(analog[0]==128);return 0;
}
