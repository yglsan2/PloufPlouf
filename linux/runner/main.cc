#include "my_application.h"

#include <stdlib.h>

int main(int argc, char** argv) {
  setenv("GTK_USE_PORTAL", "0", 1);
  setenv("GDK_DEBUG", "no-portals", 1);
  /* Évite "Unable to load from the cursor theme" si XCURSOR_PATH pas déjà défini */
  if (!getenv("XCURSOR_PATH")) {
    setenv("XCURSOR_PATH", "/usr/share/icons:/usr/share/pixmaps", 0);
  }
  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
