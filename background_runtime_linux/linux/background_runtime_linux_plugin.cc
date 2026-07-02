#include "include/background_runtime_linux/background_runtime_linux_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

#include <cstring>

#include "background_runtime_linux_private.h"

#define BACKGROUND_RUNTIME_LINUX_PLUGIN(obj)                               \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), background_runtime_linux_plugin_get_type(), \
                              BackgroundRuntimeLinuxPlugin))

struct _BackgroundRuntimeLinuxPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(BackgroundRuntimeLinuxPlugin, background_runtime_linux_plugin,
              g_object_get_type())

static void background_runtime_linux_plugin_handle_method_call(
    BackgroundRuntimeLinuxPlugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar* method = fl_method_call_get_name(method_call);

  if (strcmp(method, "initialize") == 0) {
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (strcmp(method, "startDownload") == 0) {
    g_autoptr(FlValue) result = fl_value_new_map();
    fl_value_set_string_take(result, "taskId",
                             fl_value_new_string("linux_placeholder"));
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else if (strcmp(method, "pauseDownload") == 0 ||
             strcmp(method, "resumeDownload") == 0 ||
             strcmp(method, "cancelDownload") == 0) {
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (strcmp(method, "playAudio") == 0 ||
             strcmp(method, "pauseAudio") == 0 ||
             strcmp(method, "resumeAudio") == 0 ||
             strcmp(method, "stopAudio") == 0 ||
             strcmp(method, "seekAudio") == 0) {
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (strcmp(method, "shutdown") == 0) {
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

static void background_runtime_linux_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(background_runtime_linux_plugin_parent_class)->dispose(object);
}

static void background_runtime_linux_plugin_class_init(
    BackgroundRuntimeLinuxPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = background_runtime_linux_plugin_dispose;
}

static void background_runtime_linux_plugin_init(
    BackgroundRuntimeLinuxPlugin* self) {}

static void method_call_cb(FlMethodChannel* channel,
                           FlMethodCall* method_call,
                           gpointer user_data) {
  BackgroundRuntimeLinuxPlugin* plugin =
      BACKGROUND_RUNTIME_LINUX_PLUGIN(user_data);
  background_runtime_linux_plugin_handle_method_call(plugin, method_call);
}

void background_runtime_linux_plugin_register_with_registrar(
    FlPluginRegistrar* registrar) {
  BackgroundRuntimeLinuxPlugin* plugin = BACKGROUND_RUNTIME_LINUX_PLUGIN(
      g_object_new(background_runtime_linux_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel = fl_method_channel_new(
      fl_plugin_registrar_get_messenger(registrar),
      "dev.mixin27.background_runtime/method", FL_METHOD_CODEC(codec));

  fl_method_channel_set_method_call_handler(
      channel, method_call_cb, g_object_ref(plugin), g_object_unref);

  g_object_unref(plugin);
}
