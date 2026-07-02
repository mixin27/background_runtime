#ifndef FLUTTER_PLUGIN_BACKGROUND_RUNTIME_WINDOWS_PLUGIN_H_
#define FLUTTER_PLUGIN_BACKGROUND_RUNTIME_WINDOWS_PLUGIN_H_

#include <flutter/event_channel.h>
#include <flutter/event_sink.h>
#include <flutter/event_stream_handler_functions.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

namespace background_runtime_windows {

struct PersistedDownload {
  std::string task_id;
  std::string url;
  std::string destination_path;
  std::string headers_json;
  std::string state;
  int64_t progress = 0;
  int64_t total_bytes = 0;
  bool save_to_public = false;
  int64_t created_at = 0;
  int64_t updated_at = 0;
};

struct PersistedAudioTrack {
  std::string track_id;
  std::string title;
  std::string artist;
  std::string album;
  std::string source;
  int64_t duration_millis = 0;
  int64_t position_millis = 0;
  std::string state;
};

struct PersistedConfig {
  bool enable_downloads = true;
  bool enable_audio = true;
  bool enable_notifications = false;
  bool keep_alive = true;
  bool auto_resume = true;
};

class BackgroundRuntimeWindowsPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  BackgroundRuntimeWindowsPlugin();
  virtual ~BackgroundRuntimeWindowsPlugin();

  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

 private:
  struct ActiveDownload {
    std::string url;
    std::string destination_path;
    std::string headers_json;
    bool save_to_public = false;
    void *h_request = nullptr;
    HANDLE h_file = INVALID_HANDLE_VALUE;
    int64_t bytes_received = 0;
    int64_t bytes_total = 0;
  };

  void HandleInitialize(
      const flutter::EncodableMap &args,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void HandleStartDownload(
      const flutter::EncodableMap &args,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void HandlePauseDownload(
      const flutter::EncodableMap &args,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void HandleResumeDownload(
      const flutter::EncodableMap &args,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void HandleCancelDownload(
      const flutter::EncodableMap &args,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void HandlePlayAudio(
      const flutter::EncodableMap &args,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void HandlePauseAudio(
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void HandleResumeAudio(
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void HandleStopAudio(
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void HandleSeekAudio(
      const flutter::EncodableMap &args,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void HandleShutdown(
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  void EmitDownloadEvent(const std::string &task_id,
                         const std::string &status,
                         int64_t progress,
                         int64_t total_bytes);
  void EmitPlayerState(const std::string &state,
                       const std::string &track_id,
                       const std::string &title,
                       int64_t position_millis,
                       int64_t duration_millis);
  void EmitLifecycleEvent(const std::string &state);

  void SaveDownload(const PersistedDownload &download);
  void RemoveDownload(const std::string &task_id);
  std::vector<PersistedDownload> LoadAllDownloads();
  std::vector<PersistedDownload> LoadActiveDownloads();
  void SaveAudioTrack(const PersistedAudioTrack &track);
  PersistedAudioTrack LoadAudioTrack();
  void RemoveAudioTrack();
  void SaveConfig(const PersistedConfig &config);
  PersistedConfig LoadConfig();
  std::string GetStoragePath();
  std::string ReadFile(const std::string &path);
  bool WriteFile(const std::string &path, const std::string &content);
  void RestoreState();

  bool StartWinHttp();
  void StopWinHttp();
  void StartDownloadInternal(const std::string &task_id,
                             const std::string &url,
                             const std::string &destination_path,
                             const std::string &headers_json);

  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>
      download_event_sink_;
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>
      player_state_sink_;
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>
      lifecycle_sink_;

  std::unordered_map<std::string, ActiveDownload> active_downloads_;
  PersistedConfig current_config_;

  void *session_ = nullptr;
  bool winhttp_initialized_ = false;
  bool winhttp_started_ = false;
};

}  // namespace background_runtime_windows

#endif
