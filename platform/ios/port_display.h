#ifndef PORT_DISPLAY_H
#define PORT_DISPLAY_H
/* Preserve vertical framing and original 4:3 object proportions while widening
 * only the host projection window. Never alter lifted cameras or GEO commands. */
static inline float port_wide_window(float original_width,double pixel_width,double pixel_height){
    if(pixel_width<=0||pixel_height<=0)return original_width;
    return original_width*(float)((pixel_width/pixel_height)/(4.0/3.0));
}
#endif
