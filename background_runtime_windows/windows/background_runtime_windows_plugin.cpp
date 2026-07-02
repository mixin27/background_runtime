#include "background_runtime_windows_plugin.h"

#include <flutter/encodable_map.h>
#include <flutter/encodable_value.h>
#include <flutter/event_channel.h>
#include <flutter/event_stream_handler_functions.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <Windows.h>
#include <winhttp.h>
#include <comdef.h>
#include <fstream>
#include <memory>
#include <sstream>
#include <string>
#include <vector>
#include <filesystem>

#pragma comment(lib, "winhttp.lib")

namespace background_runtime_windows {

namespace {

using flutter::EncodableMap;
using flutter::EncodableValue;

std::string GetStringFromMap(const EncodableMap &map, const std::string &key) {
  auto it = map.find(EncodableValue(key));
  if (it != map.end() && std::holds_alternative<std::string>(it->second)) {
    return std::get<std::string>(it->second);
  }
  return "";
}

int64_t GetIntFromMap(const EncodableMap &map, const std::string &key) {
  auto it = map.find(EncodableValue(key));
  if (it != map.end()) {
    if (std::holds_alternative<int>(it->second)) {
      return std::get<int>(it->second);
    }
    if (std::holds_alternative<int64_t>(it->second)) {
      return std::get<int64_t>(it->second);
    }
  }
  return 0;
}

bool GetBoolFromMap(const EncodableMap &map, const std::string &key,
                    bool default_value) {
  auto it = map.find(EncodableValue(key));
  if (it != map.end() && std::holds_alternative<bool>(it->second)) {
    return std::get<bool>(it->second);
  }
  return default_value;
}

std::string JsonEscape(const std::string &s) {
  std::string result;
  result.reserve(s.size() + 2);
  for (char c : s) {
    switch (c) {
      case '"':
        result += "\\\"";
        break;
      case '\\':
        result += "\\\\";
        break;
      case '\n':
        result += "\\n";
        break;
      case '\r':
        result += "\\r";
        break;
      case '\t':
        result += "\\t";
        break;
      default:
        result += c;
    }
  }
  return result;
}

}  // namespace

// static
void BackgroundRuntimeWindowsPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto plugin = std::make_unique<BackgroundRuntimeWindowsPlugin>();

  // Method channel
  auto method_channel = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      registrar->messenger(), "dev.mixin27.background_runtime/method",
      &flutter::StandardMethodCodec::GetInstance());

  method_channel->SetMethodCallHandler(
      [plugin_ptr = plugin.get()](const auto &call, auto result) {
        plugin_ptr->HandleMethodCall(call, std::move(result));
      });

  // Download events channel
  auto download_event_channel =
      std::make_unique<flutter::EventChannel<EncodableValue>>(
          registrar->messenger(),
          "dev.mixin27.background_runtime/downloadEvents",
          &flutter::StandardMethodCodec::GetInstance());

  download_event_channel->SetStreamHandler(
      std::make_unique<flutter::StreamHandlerFunctions<EncodableValue>>(
          [plugin_ptr = plugin.get()](
              const EncodableValue *arguments,
              std::unique_ptr<flutter::EventSink<EncodableValue>> &&events)
              -> std::unique_ptr<flutter::StreamHandlerError<EncodableValue>> {
            plugin_ptr->download_event_sink_ = std::move(events);
            return nullptr;
          },
          [plugin_ptr = plugin.get()](const EncodableValue *arguments)
              -> std::unique_ptr<flutter::StreamHandlerError<EncodableValue>> {
            plugin_ptr->download_event_sink_.reset();
            return nullptr;
          }));

  // Player state channel
  auto player_state_channel =
      std::make_unique<flutter::EventChannel<EncodableValue>>(
          registrar->messenger(),
          "dev.mixin27.background_runtime/playerState",
          &flutter::StandardMethodCodec::GetInstance());

  player_state_channel->SetStreamHandler(
      std::make_unique<flutter::StreamHandlerFunctions<EncodableValue>>(
          [plugin_ptr = plugin.get()](
              const EncodableValue *arguments,
              std::unique_ptr<flutter::EventSink<EncodableValue>> &&events)
              -> std::unique_ptr<flutter::StreamHandlerError<EncodableValue>> {
            plugin_ptr->player_state_sink_ = std::move(events);
            return nullptr;
          },
          [plugin_ptr = plugin.get()](const EncodableValue *arguments)
              -> std::unique_ptr<flutter::StreamHandlerError<EncodableValue>> {
            plugin_ptr->player_state_sink_.reset();
            return nullptr;
          }));

  // Lifecycle events channel
  auto lifecycle_event_channel =
      std::make_unique<flutter::EventChannel<EncodableValue>>(
          registrar->messenger(),
          "dev.mixin27.background_runtime/lifecycleEvents",
          &flutter::StandardMethodCodec::GetInstance());

  lifecycle_event_channel->SetStreamHandler(
      std::make_unique<flutter::StreamHandlerFunctions<EncodableValue>>(
          [plugin_ptr = plugin.get()](
              const EncodableValue *arguments,
              std::unique_ptr<flutter::EventSink<EncodableValue>> &&events)
              -> std::unique_ptr<flutter::StreamHandlerError<EncodableValue>> {
            plugin_ptr->lifecycle_sink_ = std::move(events);
            return nullptr;
          },
          [plugin_ptr = plugin.get()](const EncodableValue *arguments)
              -> std::unique_ptr<flutter::StreamHandlerError<EncodableValue>> {
            plugin_ptr->lifecycle_sink_.reset();
            return nullptr;
          }));

  registrar->AddPlugin(std::move(plugin));
}

BackgroundRuntimeWindowsPlugin::BackgroundRuntimeWindowsPlugin() {
  current_config_ = LoadConfig();
}

BackgroundRuntimeWindowsPlugin::~BackgroundRuntimeWindowsPlugin() {
  StopWinHttp();
}

void BackgroundRuntimeWindowsPlugin::HandleMethodCall(
    const flutter::MethodCall<EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  const auto &method_name = method_call.method_name();

  if (method_name == "initialize") {
    HandleInitialize(
        std::get<EncodableMap>(*method_call.arguments()),
        std::move(result));
  } else if (method_name == "startDownload") {
    HandleStartDownload(
        std::get<EncodableMap>(*method_call.arguments()),
        std::move(result));
  } else if (method_name == "pauseDownload") {
    HandlePauseDownload(
        std::get<EncodableMap>(*method_call.arguments()),
        std::move(result));
  } else if (method_name == "resumeDownload") {
    HandleResumeDownload(
        std::get<EncodableMap>(*method_call.arguments()),
        std::move(result));
  } else if (method_name == "cancelDownload") {
    HandleCancelDownload(
        std::get<EncodableMap>(*method_call.arguments()),
        std::move(result));
  } else if (method_name == "playAudio") {
    HandlePlayAudio(
        std::get<EncodableMap>(*method_call.arguments()),
        std::move(result));
  } else if (method_name == "pauseAudio") {
    HandlePauseAudio(std::move(result));
  } else if (method_name == "resumeAudio") {
    HandleResumeAudio(std::move(result));
  } else if (method_name == "stopAudio") {
    HandleStopAudio(std::move(result));
  } else if (method_name == "seekAudio") {
    HandleSeekAudio(
        std::get<EncodableMap>(*method_call.arguments()),
        std::move(result));
  } else if (method_name == "shutdown") {
    HandleShutdown(std::move(result));
  } else {
    result->NotImplemented();
  }
}

// MARK: - Initialize

void BackgroundRuntimeWindowsPlugin::HandleInitialize(
    const EncodableMap &args,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  auto config_it = args.find(EncodableValue("config"));
  if (config_it == args.end() ||
      !std::holds_alternative<EncodableMap>(config_it->second)) {
    result->Error("INVALID_ARGUMENT", "Missing config");
    return;
  }
  const auto &config_map = std::get<EncodableMap>(config_it->second);

  PersistedConfig config;
  config.enable_downloads = GetBoolFromMap(config_map, "enableDownloads", true);
  config.enable_audio = GetBoolFromMap(config_map, "enableAudio", true);
  config.enable_notifications =
      GetBoolFromMap(config_map, "enableNotifications", false);
  config.keep_alive = GetBoolFromMap(config_map, "keepAlive", true);
  config.auto_resume = GetBoolFromMap(config_map, "autoResume", true);
  SaveConfig(config);
  current_config_ = config;

  if (config.enable_downloads) {
    StartWinHttp();
  }

  if (config.auto_resume) {
    RestoreState();
  }

  EmitLifecycleEvent("INITIALIZED");
  result->Success();
}

void BackgroundRuntimeWindowsPlugin::RestoreState() {
  auto active = LoadActiveDownloads();
  for (const auto &download : active) {
    RemoveDownload(download.task_id);
    HandleStartDownload(
        {{EncodableValue("request"),
          EncodableValue(EncodableMap{
              {EncodableValue("url"), EncodableValue(download.url)},
              {EncodableValue("destinationPath"),
               EncodableValue(download.destination_path)},
              {EncodableValue("headers"),
               EncodableValue(download.headers_json)},
              {EncodableValue("saveToPublic"),
               EncodableValue(download.save_to_public)},
          })}},
        std::make_unique<flutter::MethodResultFunctions<EncodableValue>>(
            [](const EncodableValue *) {}, nullptr, nullptr));
  }
}

// MARK: - WinHTTP

bool BackgroundRuntimeWindowsPlugin::StartWinHttp() {
  if (winhttp_started_)
    return true;
  session_ = WinHttpOpen(L"BackgroundRuntime/1.0",
                         WINHTTP_ACCESS_TYPE_DEFAULT_PROXY, nullptr, nullptr, 0);
  if (!session_) {
    return false;
  }
  winhttp_started_ = true;
  return true;
}

void BackgroundRuntimeWindowsPlugin::StopWinHttp() {
  if (!winhttp_started_)
    return;
  for (auto &[task_id, download] : active_downloads_) {
    if (download.h_request) {
      WinHttpCloseHandle(download.h_request);
      download.h_request = nullptr;
    }
    if (download.h_file != INVALID_HANDLE_VALUE) {
      CloseHandle(download.h_file);
      download.h_file = INVALID_HANDLE_VALUE;
    }
  }
  active_downloads_.clear();
  if (session_) {
    WinHttpCloseHandle(session_);
    session_ = nullptr;
  }
  winhttp_started_ = false;
}

void CALLBACK WinHttpStatusCallback(HINTERNET h_request,
                                    DWORD_PTR context,
                                    DWORD status,
                                    LPVOID info,
                                    DWORD info_len) {
  auto *plugin = reinterpret_cast<BackgroundRuntimeWindowsPlugin *>(context);
  if (!plugin)
    return;

  // Find the task_id for this request
  std::string task_id;
  for (const auto &[tid, dl] : plugin->active_downloads_) {
    if (dl.h_request == h_request) {
      task_id = tid;
      break;
    }
  }
  if (task_id.empty())
    return;

  auto it = plugin->active_downloads_.find(task_id);
  if (it == plugin->active_downloads_.end())
    return;

  auto &download = it->second;

  switch (status) {
    case WINHTTP_CALLBACK_STATUS_HEADERS_AVAILABLE: {
      DWORD content_length = 0;
      DWORD size = sizeof(content_length);
      WinHttpQueryHeaders(h_request,
                          WINHTTP_QUERY_CONTENT_LENGTH | WINHTTP_QUERY_FLAG_NUMBER,
                          nullptr, &content_length, &size, nullptr);
      download.bytes_total = static_cast<int64_t>(content_length);

      // Create the file
      std::string path = download.destination_path;
      std::filesystem::create_directories(
          std::filesystem::path(path).parent_path());
      download.h_file =
          CreateFileA(path.c_str(), GENERIC_WRITE, 0, nullptr,
                      CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);

      // Start reading data
      WinHttpQueryDataAvailable(h_request, nullptr);
      break;
    }
    case WINHTTP_CALLBACK_STATUS_DATA_AVAILABLE: {
      if (info_len > 0) {
        DWORD available = *reinterpret_cast<DWORD *>(info);
        WinHttpReadData(h_request, new char[available], available, nullptr);
      }
      break;
    }
    case WINHTTP_CALLBACK_STATUS_READ_COMPLETE: {
      if (info && info_len > 0) {
        DWORD written = 0;
        WriteFile(download.h_file, info, info_len, &written, nullptr);
        download.bytes_received += info_len;
        plugin->EmitDownloadEvent(task_id, "DOWNLOADING",
                                  download.bytes_received,
                                  download.bytes_total);
        delete[] static_cast<char *>(info);
        WinHttpQueryDataAvailable(h_request, nullptr);
      } else {
        // Download complete
        if (download.h_file != INVALID_HANDLE_VALUE) {
          CloseHandle(download.h_file);
          download.h_file = INVALID_HANDLE_VALUE;
        }
        plugin->EmitDownloadEvent(task_id, "COMPLETED",
                                  download.bytes_received,
                                  download.bytes_total);
        plugin->active_downloads_.erase(task_id);
      }
      break;
    }
    case WINHTTP_CALLBACK_STATUS_REQUEST_ERROR: {
      if (download.h_file != INVALID_HANDLE_VALUE) {
        CloseHandle(download.h_file);
        download.h_file = INVALID_HANDLE_VALUE;
      }
      plugin->EmitDownloadEvent(task_id, "FAILED",
                                download.bytes_received,
                                download.bytes_total);
      plugin->active_downloads_.erase(task_id);
      break;
    }
  }
}

void BackgroundRuntimeWindowsPlugin::StartDownloadInternal(
    const std::string &task_id,
    const std::string &url,
    const std::string &destination_path,
    const std::string &headers_json) {
  if (!winhttp_started_)
    return;

  // Parse URL
  URL_COMPONENTSA url_comp = {sizeof(URL_COMPONENTSA)};
  url_comp.dwSchemeLength = (DWORD)-1;
  url_comp.dwHostNameLength = (DWORD)-1;
  url_comp.dwUrlPathLength = (DWORD)-1;
  url_comp.dwExtraInfoLength = (DWORD)-1;
  WinHttpCrackUrlA(url.c_str(), static_cast<DWORD>(url.size()), 0, &url_comp);

  std::string hostname(url_comp.lpszHostName, url_comp.dwHostNameLength);
  std::string path(url_comp.lpszUrlPath, url_comp.dwUrlPathLength);
  if (url_comp.dwExtraInfoLength > 0) {
    path += std::string(url_comp.lpszExtraInfo, url_comp.dwExtraInfoLength);
  }

  auto &download = active_downloads_[task_id];
  download.url = url;
  download.destination_path = destination_path;
  download.h_file = INVALID_HANDLE_VALUE;

  HINTERNET h_connect = WinHttpConnect(
      session_, std::wstring(hostname.begin(), hostname.end()).c_str(),
      url_comp.nPort, 0);
  if (!h_connect) {
    EmitDownloadEvent(task_id, "FAILED", 0, 0);
    active_downloads_.erase(task_id);
    return;
  }

  download.h_request = WinHttpOpenRequest(
      h_connect, L"GET", std::wstring(path.begin(), path.end()).c_str(),
      nullptr, nullptr, nullptr,
      WINHTTP_FLAG_SECURE);
  if (!download.h_request) {
    WinHttpCloseHandle(h_connect);
    EmitDownloadEvent(task_id, "FAILED", 0, 0);
    active_downloads_.erase(task_id);
    return;
  }

  WinHttpSetStatusCallback(
      download.h_request, WinHttpStatusCallback,
      WINHTTP_CALLBACK_FLAG_ALL_DATA_COMPLETED |
          WINHTTP_CALLBACK_FLAG_DATA_AVAILABLE |
          WINHTTP_CALLBACK_FLAG_HEADERS_AVAILABLE |
          WINHTTP_CALLBACK_FLAG_READ_COMPLETE |
          WINHTTP_CALLBACK_FLAG_REQUEST_ERROR,
      0);

  WinHttpSendRequest(download.h_request, nullptr, 0, nullptr, 0, 0,
                     reinterpret_cast<DWORD_PTR>(this));
  WinHttpReceiveResponse(download.h_request, nullptr);
}

void BackgroundRuntimeWindowsPlugin::EmitDownloadEvent(
    const std::string &task_id,
    const std::string &status,
    int64_t progress,
    int64_t total_bytes) {
  if (!download_event_sink_)
    return;

  EncodableMap event;
  event[EncodableValue("taskId")] = EncodableValue(task_id);
  event[EncodableValue("status")] = EncodableValue(status);
  event[EncodableValue("state")] = EncodableValue(
      status == "COMPLETED" ? "completed"
                            : status == "FAILED" ? "failed"
                                                 : status == "CANCELLED"
                                                       ? "cancelled"
                                                       : "downloading");
  if (progress >= 0) {
    event[EncodableValue("progress")] =
        EncodableValue(static_cast<int64_t>(progress));
  }
  if (total_bytes >= 0) {
    event[EncodableValue("totalBytes")] =
        EncodableValue(static_cast<int64_t>(total_bytes));
  }

  download_event_sink_->Success(EncodableValue(event));
}

void BackgroundRuntimeWindowsPlugin::EmitPlayerState(
    const std::string &state,
    const std::string &track_id,
    const std::string &title,
    int64_t position_millis,
    int64_t duration_millis) {
  if (!player_state_sink_)
    return;

  EncodableMap event;
  event[EncodableValue("state")] = EncodableValue(state);
  event[EncodableValue("positionMillis")] =
      EncodableValue(static_cast<int64_t>(position_millis));
  if (!track_id.empty())
    event[EncodableValue("trackId")] = EncodableValue(track_id);
  if (!title.empty())
    event[EncodableValue("title")] = EncodableValue(title);
  if (duration_millis > 0) {
    event[EncodableValue("durationMillis")] =
        EncodableValue(static_cast<int64_t>(duration_millis));
  }

  player_state_sink_->Success(EncodableValue(event));
}

void BackgroundRuntimeWindowsPlugin::EmitLifecycleEvent(
    const std::string &state) {
  if (!lifecycle_sink_)
    return;

  EncodableMap event;
  event[EncodableValue("state")] = EncodableValue(state);
  lifecycle_sink_->Success(EncodableValue(event));
}

// MARK: - Download Handlers

void BackgroundRuntimeWindowsPlugin::HandleStartDownload(
    const EncodableMap &args,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  auto request_it = args.find(EncodableValue("request"));
  if (request_it == args.end() ||
      !std::holds_alternative<EncodableMap>(request_it->second)) {
    result->Error("DOWNLOAD_FAILED", "Invalid request");
    return;
  }
  const auto &request = std::get<EncodableMap>(request_it->second);

  std::string url = GetStringFromMap(request, "url");
  std::string destination_path = GetStringFromMap(request, "destinationPath");
  std::string headers = GetStringFromMap(request, "headers");
  bool save_to_public = GetBoolFromMap(request, "saveToPublic", false);

  if (url.empty() || destination_path.empty()) {
    result->Error("DOWNLOAD_FAILED", "Missing url or destinationPath");
    return;
  }

  std::string task_id =
      std::to_string(reinterpret_cast<uintptr_t>(this)) + "_" +
      std::to_string(GetTickCount64()) + "_" +
      std::to_string(active_downloads_.size());

  if (!winhttp_started_) {
    StartWinHttp();
  }

  StartDownloadInternal(task_id, url, destination_path, headers);

  PersistedDownload persisted;
  persisted.task_id = task_id;
  persisted.url = url;
  persisted.destination_path = destination_path;
  persisted.headers_json = headers;
  persisted.state = "DOWNLOADING";
  persisted.progress = 0;
  persisted.total_bytes = 0;
  persisted.save_to_public = save_to_public;
  persisted.created_at = static_cast<int64_t>(GetTickCount64());
  persisted.updated_at = static_cast<int64_t>(GetTickCount64());
  SaveDownload(persisted);

  EncodableMap response;
  response[EncodableValue("taskId")] = EncodableValue(task_id);
  result->Success(EncodableValue(response));
}

void BackgroundRuntimeWindowsPlugin::HandlePauseDownload(
    const EncodableMap &args,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  std::string task_id = GetStringFromMap(args, "taskId");
  if (task_id.empty()) {
    result->Error("TASK_NOT_FOUND", "Missing taskId");
    return;
  }

  auto it = active_downloads_.find(task_id);
  if (it == active_downloads_.end()) {
    result->Error("TASK_NOT_FOUND", "Download task not found");
    return;
  }

  // WinHTTP doesn't support true pause; we cancel and save resume info
  if (it->second.h_request) {
    WinHttpCloseHandle(it->second.h_request);
  }
  if (it->second.h_file != INVALID_HANDLE_VALUE) {
    CloseHandle(it->second.h_file);
  }
  active_downloads_.erase(it);

  EmitDownloadEvent(task_id, "PAUSED", 0, 0);
  result->Success();
}

void BackgroundRuntimeWindowsPlugin::HandleResumeDownload(
    const EncodableMap &args,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  result->Error("NO_RESUME_DATA", "Resume not supported on Windows");
}

void BackgroundRuntimeWindowsPlugin::HandleCancelDownload(
    const EncodableMap &args,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  std::string task_id = GetStringFromMap(args, "taskId");
  if (task_id.empty()) {
    result->Error("TASK_NOT_FOUND", "Missing taskId");
    return;
  }

  auto it = active_downloads_.find(task_id);
  if (it == active_downloads_.end()) {
    result->Error("TASK_NOT_FOUND", "Download task not found");
    return;
  }

  if (it->second.h_request) {
    WinHttpCloseHandle(it->second.h_request);
  }
  if (it->second.h_file != INVALID_HANDLE_VALUE) {
    CloseHandle(it->second.h_file);
  }
  active_downloads_.erase(it);
  RemoveDownload(task_id);

  EmitDownloadEvent(task_id, "CANCELLED", 0, 0);
  result->Success();
}

// MARK: - Audio Handlers

void BackgroundRuntimeWindowsPlugin::HandlePlayAudio(
    const EncodableMap &args,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  auto track_it = args.find(EncodableValue("track"));
  if (track_it == args.end() ||
      !std::holds_alternative<EncodableMap>(track_it->second)) {
    result->Error("PLAYBACK_FAILED", "Invalid track");
    return;
  }
  const auto &track = std::get<EncodableMap>(track_it->second);

  std::string source = GetStringFromMap(track, "source");
  std::string track_id = GetStringFromMap(track, "id");
  std::string title = GetStringFromMap(track, "title");

  // On Windows, audio playback is best-effort via ShellExecute
  // This opens the URL in the default media player.
  // For full integration, Windows.Media.Playback would be needed
  // via C++/WinRT.

  if (!source.empty() && current_config_.enable_audio) {
    std::wstring wide_source(source.begin(), source.end());
    ShellExecuteW(nullptr, L"open", wide_source.c_str(), nullptr, nullptr,
                  SW_SHOWNORMAL);
  }

  EmitPlayerState("PLAYING", track_id, title, 0, 0);
  result->Success();
}

void BackgroundRuntimeWindowsPlugin::HandlePauseAudio(
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  EmitPlayerState("PAUSED", "", "", 0, 0);
  result->Success();
}

void BackgroundRuntimeWindowsPlugin::HandleResumeAudio(
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  EmitPlayerState("PLAYING", "", "", 0, 0);
  result->Success();
}

void BackgroundRuntimeWindowsPlugin::HandleStopAudio(
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  EmitPlayerState("STOPPED", "", "", 0, 0);
  result->Success();
}

void BackgroundRuntimeWindowsPlugin::HandleSeekAudio(
    const EncodableMap &args,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  result->Success();
}

// MARK: - Shutdown

void BackgroundRuntimeWindowsPlugin::HandleShutdown(
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  StopWinHttp();
  download_event_sink_.reset();
  player_state_sink_.reset();
  lifecycle_sink_.reset();
  EmitLifecycleEvent("SHUTDOWN");
  result->Success();
}

// MARK: - Persistence

std::string BackgroundRuntimeWindowsPlugin::GetStoragePath() {
  char appdata[MAX_PATH];
  if (SHGetFolderPathA(nullptr, CSIDL_LOCAL_APPDATA, nullptr, 0, appdata) !=
      S_OK) {
    return "background_runtime";
  }
  std::string path = std::string(appdata) + "\\background_runtime";
  std::filesystem::create_directories(path);
  return path;
}

std::string BackgroundRuntimeWindowsPlugin::ReadFile(const std::string &path) {
  std::ifstream file(path);
  if (!file.is_open())
    return "";
  std::stringstream ss;
  ss << file.rdbuf();
  return ss.str();
}

bool BackgroundRuntimeWindowsPlugin::WriteFile(const std::string &path,
                                                const std::string &content) {
  std::ofstream file(path);
  if (!file.is_open())
    return false;
  file << content;
  return file.good();
}

void BackgroundRuntimeWindowsPlugin::SaveDownload(
    const PersistedDownload &download) {
  auto all = LoadAllDownloads();
  bool found = false;
  for (auto &d : all) {
    if (d.task_id == download.task_id) {
      d = download;
      found = true;
      break;
    }
  }
  if (!found) {
    all.push_back(download);
  }

  std::string json = "[\n";
  for (size_t i = 0; i < all.size(); ++i) {
    const auto &d = all[i];
    json += "  {\n";
    json += "    \"taskId\": \"" + JsonEscape(d.task_id) + "\",\n";
    json += "    \"url\": \"" + JsonEscape(d.url) + "\",\n";
    json += "    \"destinationPath\": \"" + JsonEscape(d.destination_path) +
            "\",\n";
    json += "    \"headersJson\": \"" + JsonEscape(d.headers_json) + "\",\n";
    json += "    \"state\": \"" + JsonEscape(d.state) + "\",\n";
    json += "    \"progress\": " + std::to_string(d.progress) + ",\n";
    json += "    \"totalBytes\": " + std::to_string(d.total_bytes) + ",\n";
    json += "    \"saveToPublic\": " + std::string(d.save_to_public ? "true" : "false") + ",\n";
    json += "    \"createdAt\": " + std::to_string(d.created_at) + ",\n";
    json += "    \"updatedAt\": " + std::to_string(d.updated_at) + "\n";
    json += "  }" + (i < all.size() - 1 ? "," : "") + "\n";
  }
  json += "]\n";

  WriteFile(GetStoragePath() + "\\downloads.json", json);
}

void BackgroundRuntimeWindowsPlugin::RemoveDownload(
    const std::string &task_id) {
  auto all = LoadAllDownloads();
  all.erase(std::remove_if(all.begin(), all.end(),
                           [&](const PersistedDownload &d) {
                             return d.task_id == task_id;
                           }),
            all.end());

  std::string json = "[\n";
  for (size_t i = 0; i < all.size(); ++i) {
    const auto &d = all[i];
    json += "  {\n";
    json += "    \"taskId\": \"" + JsonEscape(d.task_id) + "\",\n";
    json += "    \"url\": \"" + JsonEscape(d.url) + "\",\n";
    json += "    \"destinationPath\": \"" + JsonEscape(d.destination_path) +
            "\",\n";
    json += "    \"headersJson\": \"" + JsonEscape(d.headers_json) + "\",\n";
    json += "    \"state\": \"" + JsonEscape(d.state) + "\",\n";
    json += "    \"progress\": " + std::to_string(d.progress) + ",\n";
    json += "    \"totalBytes\": " + std::to_string(d.total_bytes) + ",\n";
    json += "    \"saveToPublic\": " +
            std::string(d.save_to_public ? "true" : "false") + ",\n";
    json += "    \"createdAt\": " + std::to_string(d.created_at) + ",\n";
    json += "    \"updatedAt\": " + std::to_string(d.updated_at) + "\n";
    json += "  }" + (i < all.size() - 1 ? "," : "") + "\n";
  }
  json += "]\n";

  WriteFile(GetStoragePath() + "\\downloads.json", json);
}

std::vector<PersistedDownload>
BackgroundRuntimeWindowsPlugin::LoadAllDownloads() {
  std::vector<PersistedDownload> result;
  std::string content = ReadFile(GetStoragePath() + "\\downloads.json");
  if (content.empty())
    return result;

  // Simple JSON array parser
  size_t pos = 0;
  while ((pos = content.find('{', pos)) != std::string::npos) {
    size_t end = content.find('}', pos);
    if (end == std::string::npos)
      break;

    std::string obj = content.substr(pos, end - pos + 1);
    pos = end + 1;

    PersistedDownload d;
    auto get_field = [&](const std::string &key) -> std::string {
      auto kpos = obj.find("\"" + key + "\"");
      if (kpos == std::string::npos)
        return "";
      auto vpos = obj.find(':', kpos);
      if (vpos == std::string::npos)
        return "";
      vpos++;
      while (vpos < obj.size() && (obj[vpos] == ' ' || obj[vpos] == '\n' ||
                                   obj[vpos] == '\r' || obj[vpos] == '\t'))
        vpos++;
      if (vpos < obj.size() && obj[vpos] == '"') {
        vpos++;
        std::string val;
        while (vpos < obj.size() && obj[vpos] != '"') {
          if (obj[vpos] == '\\' && vpos + 1 < obj.size()) {
            vpos++;
            if (obj[vpos] == '"')
              val += '"';
            else if (obj[vpos] == 'n')
              val += '\n';
            else if (obj[vpos] == 'r')
              val += '\r';
            else if (obj[vpos] == 't')
              val += '\t';
            else if (obj[vpos] == '\\')
              val += '\\';
            else
              val += obj[vpos];
          } else {
            val += obj[vpos];
          }
          vpos++;
        }
        return val;
      }
      // number
      std::string num;
      while (vpos < obj.size() && (isdigit(obj[vpos]) || obj[vpos] == '-'))
        num += obj[vpos++];
      return num;
    };

    d.task_id = get_field("taskId");
    d.url = get_field("url");
    d.destination_path = get_field("destinationPath");
    d.headers_json = get_field("headersJson");
    d.state = get_field("state");
    d.progress = std::stoll(get_field("progress").empty() ? "0"
                                                          : get_field("progress"));
    d.total_bytes = std::stoll(get_field("totalBytes").empty() ? "0"
                                                              : get_field("totalBytes"));
    d.save_to_public = get_field("saveToPublic") == "true";
    d.created_at = std::stoll(get_field("createdAt").empty() ? "0"
                                                            : get_field("createdAt"));
    d.updated_at = std::stoll(get_field("updatedAt").empty() ? "0"
                                                            : get_field("updatedAt"));

    if (!d.task_id.empty())
      result.push_back(d);
  }

  return result;
}

std::vector<PersistedDownload>
BackgroundRuntimeWindowsPlugin::LoadActiveDownloads() {
  auto all = LoadAllDownloads();
  std::vector<PersistedDownload> active;
  for (const auto &d : all) {
    if (d.state == "DOWNLOADING" || d.state == "PAUSED") {
      active.push_back(d);
    }
  }
  return active;
}

void BackgroundRuntimeWindowsPlugin::SaveAudioTrack(
    const PersistedAudioTrack &track) {
  std::string json;
  json += "{\n";
  json += "  \"trackId\": \"" + JsonEscape(track.track_id) + "\",\n";
  json += "  \"title\": \"" + JsonEscape(track.title) + "\",\n";
  json += "  \"artist\": \"" + JsonEscape(track.artist) + "\",\n";
  json += "  \"album\": \"" + JsonEscape(track.album) + "\",\n";
  json += "  \"source\": \"" + JsonEscape(track.source) + "\",\n";
  json += "  \"durationMillis\": " + std::to_string(track.duration_millis) +
          ",\n";
  json += "  \"positionMillis\": " + std::to_string(track.position_millis) +
          ",\n";
  json += "  \"state\": \"" + JsonEscape(track.state) + "\"\n";
  json += "}\n";
  WriteFile(GetStoragePath() + "\\audio_track.json", json);
}

PersistedAudioTrack BackgroundRuntimeWindowsPlugin::LoadAudioTrack() {
  PersistedAudioTrack track;
  std::string content = ReadFile(GetStoragePath() + "\\audio_track.json");
  if (content.empty())
    return track;

  auto get_field = [&](const std::string &key) -> std::string {
    auto kpos = content.find("\"" + key + "\"");
    if (kpos == std::string::npos)
      return "";
    auto vpos = content.find(':', kpos);
    if (vpos == std::string::npos)
      return "";
    vpos++;
    while (vpos < content.size() && content[vpos] == ' ')
      vpos++;
    if (vpos < content.size() && content[vpos] == '"') {
      vpos++;
      std::string val;
      while (vpos < content.size() && content[vpos] != '"') {
        if (content[vpos] == '\\' && vpos + 1 < content.size()) {
          vpos++;
          if (content[vpos] == '"')
            val += '"';
          else
            val += content[vpos];
        } else {
          val += content[vpos];
        }
        vpos++;
      }
      return val;
    }
    std::string num;
    while (vpos < content.size() && (isdigit(content[vpos]) || content[vpos] == '-'))
      num += content[vpos++];
    return num;
  };

  track.track_id = get_field("trackId");
  track.title = get_field("title");
  track.artist = get_field("artist");
  track.album = get_field("album");
  track.source = get_field("source");
  track.duration_millis = std::stoll(get_field("durationMillis").empty() ? "0" : get_field("durationMillis"));
  track.position_millis = std::stoll(get_field("positionMillis").empty() ? "0" : get_field("positionMillis"));
  track.state = get_field("state");

  return track;
}

void BackgroundRuntimeWindowsPlugin::RemoveAudioTrack() {
  WriteFile(GetStoragePath() + "\\audio_track.json", "");
}

void BackgroundRuntimeWindowsPlugin::SaveConfig(const PersistedConfig &config) {
  std::string json;
  json += "{\n";
  json += "  \"enableDownloads\": " +
          std::string(config.enable_downloads ? "true" : "false") + ",\n";
  json += "  \"enableAudio\": " +
          std::string(config.enable_audio ? "true" : "false") + ",\n";
  json += "  \"enableNotifications\": " +
          std::string(config.enable_notifications ? "true" : "false") + ",\n";
  json += "  \"keepAlive\": " +
          std::string(config.keep_alive ? "true" : "false") + ",\n";
  json += "  \"autoResume\": " +
          std::string(config.auto_resume ? "true" : "false") + "\n";
  json += "}\n";
  WriteFile(GetStoragePath() + "\\config.json", json);
}

PersistedConfig BackgroundRuntimeWindowsPlugin::LoadConfig() {
  PersistedConfig config;
  std::string content = ReadFile(GetStoragePath() + "\\config.json");
  if (content.empty())
    return config;

  config.enable_downloads = content.find("\"enableDownloads\": true") != std::string::npos;
  config.enable_audio = content.find("\"enableAudio\": true") != std::string::npos;
  config.enable_notifications = content.find("\"enableNotifications\": true") != std::string::npos;
  config.keep_alive = content.find("\"keepAlive\": true") != std::string::npos;
  config.auto_resume = content.find("\"autoResume\": true") != std::string::npos;

  return config;
}

}  // namespace background_runtime_windows
