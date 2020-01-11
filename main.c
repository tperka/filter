#include "allegro5/allegro.h"
#include "allegro5/allegro_image.h"
#include "allegro5/allegro_native_dialog.h"
#include "filter.h"

#include <stdio.h>
int main(int argc, char **argv){
   ALLEGRO_DISPLAY *display = NULL;
   ALLEGRO_BITMAP  *image   = NULL;
   ALLEGRO_EVENT_QUEUE *event_queue = NULL;
   ALLEGRO_LOCKED_REGION *region = NULL;
   
  
   
   if(!al_init()) {
      al_show_native_message_box(display, "Error", "Error", "Failed to initialize allegro!", 
                                 NULL, ALLEGRO_MESSAGEBOX_ERROR);
      return -1;
   }
   if(!al_install_mouse()) {
      al_show_native_message_box(display, "Error", "Error", "Failed to initialize mouse!", 
                                 NULL, ALLEGRO_MESSAGEBOX_ERROR);
      return -1;
   }

   if(!al_init_image_addon()) {
      al_show_native_message_box(display, "Error", "Error", "Failed to initialize al_init_image_addon!", 
                                 NULL, ALLEGRO_MESSAGEBOX_ERROR);
      return -1;
   }
   image = al_load_bitmap(argv[1]);
   
   if(!image) {
      al_show_native_message_box(display, "Error", "Error", "Failed to load image!", 
                                 NULL, ALLEGRO_MESSAGEBOX_ERROR);
      return -1;
   }
   const int HEIGHT = al_get_bitmap_height(image);
   const int WIDTH = al_get_bitmap_width(image);

   display = al_create_display(WIDTH,HEIGHT);
   
   if(!display) {
      al_show_native_message_box(display, "Error", "Error", "Failed to initialize display!", 
                                 NULL, ALLEGRO_MESSAGEBOX_ERROR);
      al_destroy_bitmap(image);
      return -1;
   }
   al_set_window_title(display,"Filtr konwulsyjny");

   al_convert_memory_bitmaps();
   al_draw_bitmap(image,0,0,0);

   event_queue = al_create_event_queue();
   
   if(!event_queue){
      al_show_native_message_box(display, "Error", "Error", "Failed to create event queue!", 
                                 NULL, ALLEGRO_MESSAGEBOX_ERROR);
      al_destroy_display(display);
      al_destroy_bitmap(image);
      return -1;
   }
   al_register_event_source(event_queue, al_get_display_event_source(display));
   al_register_event_source(event_queue, al_get_mouse_event_source());
   
   
   al_flip_display();

   unsigned char* pixelBuffer = NULL;
   while(1)
   {
      ALLEGRO_EVENT ev;
      al_wait_for_event(event_queue, &ev);
      if(ev.type == ALLEGRO_EVENT_DISPLAY_CLOSE)
      {
         break;
      }
      else if(ev.type == ALLEGRO_EVENT_MOUSE_BUTTON_DOWN && ev.mouse.button == 1)
      {     
         region = al_lock_bitmap(image, ALLEGRO_PIXEL_FORMAT_ANY_24_NO_ALPHA, ALLEGRO_LOCK_READWRITE);
         pixelBuffer = (unsigned char*) region -> data;
			pixelBuffer -= (-region->pitch * (HEIGHT-1));
   
         pixelBuffer = filter(pixelBuffer, -region->pitch, HEIGHT, ev.mouse.x, HEIGHT-ev.mouse.y);
         al_unlock_bitmap(image);
         al_draw_bitmap(image, 0,0,0);
         al_flip_display();
      }  
   }
   al_destroy_display(display);
   al_destroy_bitmap(image);
   al_destroy_event_queue(event_queue);
   return 0;
}