# AGENTS.md

# background_runtime

Production-grade federated Flutter plugin for long-running background execution.

---

# Mission

This repository is NOT an example project.

This repository is intended to become a production-quality Flutter plugin comparable to official Flutter plugins.

Every change must improve long-term maintainability.

Prefer correctness over speed.

Never generate prototype-quality code.

---

# High-Level Goals

The plugin provides a unified background runtime across:

- Android
- iOS
- macOS
- Windows
- Linux
- Web

Capabilities include:

- Background download
- Audio playback
- Native notifications
- Background task execution
- State restoration
- Progress events
- Resume support
- Extensible runtime modules

The public Dart API should remain platform-independent.

---

# Engineering Principles

Follow:

- SOLID
- Clean Architecture
- DRY
- KISS
- Composition over inheritance
- Explicit dependencies
- Immutable models
- Null Safety
- Strong typing

Never sacrifice maintainability for fewer lines of code.

---

# Repository Structure

background_runtime/
background_runtime_platform_interface/
background_runtime_android/
background_runtime_ios/
background_runtime_macos/
background_runtime_windows/
background_runtime_linux/
background_runtime_web/
example/

Each package should compile independently.

---

# Platform Responsibilities

## Android

Language:

Kotlin

Use:

- Foreground Service
- Media3
- MediaSession
- WorkManager
- Room
- OkHttp
- NotificationCompat
- Coroutines
- Flow

Never use deprecated Android APIs.

Support Android API 24+.

---

## iOS

Language:

Swift

Use:

- URLSession
- Background Configuration
- AVFoundation
- NotificationCenter

Never use Objective-C.

---

## macOS

Language:

Swift

Use native Apple APIs whenever possible.

---

## Windows

Language:

C++

Use WinRT APIs when applicable.

---

## Linux

Language:

C++

Use:

- libcurl
- SQLite
- GStreamer

---

## Web

Implement best-effort support.

Document unsupported features.

---

# Architecture

Every platform should follow:

Service Layer

↓

Repository

↓

Native Runtime

↓

Platform Bridge

↓

Flutter

Avoid God classes.

Each class should have one responsibility.

---

# Dart API Rules

The Dart API must be:

Small

Predictable

Strongly Typed

Platform Independent

Avoid exposing platform-specific concepts.

Bad:

AndroidForegroundService

Good:

BackgroundRuntime

---

# Communication

Use:

MethodChannel

for commands.

Use:

EventChannel

for streams.

Prefer Pigeon for large APIs.

Avoid JSON maps whenever possible.

---

# State Management

Persist runtime state.

Examples:

Downloads

Playback Queue

Progress

Errors

Resume Position

Never rely only on memory.

---

# Threading

Never block UI threads.

Android:

Coroutines

Swift:

async/await

Desktop:

Background workers

Use asynchronous APIs whenever available.

---

# Error Handling

Never throw generic Exception.

Create typed errors.

Example:

DownloadFailed

StorageUnavailable

PermissionDenied

NetworkUnavailable

ServiceUnavailable

Include:

error code

message

cause

---

# Logging

Every important operation should log.

Use structured logging.

Avoid print().

Logs should help debugging.

---

# Dependency Injection

Prefer constructor injection.

Avoid service locators.

Avoid global mutable state.

---

# Models

Models must be immutable.

Use value equality.

Avoid mutable public fields.

---

# Testing Requirements

Every feature must include tests.

Minimum:

Unit Tests

Platform Interface Tests

Integration Tests

Fake Platform Implementation

Mock Channels

No feature is complete without tests.

---

# Documentation

Every public API requires documentation.

Maintain:

Architecture.md

PluginAPI.md

PlatformSupport.md

CHANGELOG.md

README.md

Keep documentation synchronized with implementation.

---

# Code Generation

Generated files should never be manually edited.

Document generation commands.

---

# Performance

Avoid unnecessary allocations.

Avoid duplicate streams.

Avoid polling.

Prefer event-driven architecture.

Minimize channel traffic.

---

# Backward Compatibility

Avoid breaking public APIs.

When necessary:

Deprecate first.

Remove later.

Document migration.

---

# Security

Validate all file paths.

Never trust external input.

Avoid arbitrary file access.

Avoid unsafe permissions.

Protect user privacy.

---

# Pull Request Standards

Every PR should:

Compile

Pass tests

Update documentation

Avoid unrelated refactoring

Explain architectural decisions

---

# AI Coding Instructions

When implementing features:

1. Understand existing architecture first.

2. Do not duplicate code.

3. Reuse existing abstractions.

4. Explain architectural decisions before coding.

5. Produce compilable code.

6. Generate tests.

7. Update documentation.

8. Never leave TODOs.

9. Never create placeholder implementations.

10. Never invent APIs that do not exist.

---

# Coding Style

Prefer readability over cleverness.

Use descriptive names.

Keep methods short.

Keep files focused.

Avoid nested logic.

Prefer early returns.

Avoid magic numbers.

Use constants.

---

# Flutter Style

Follow Effective Dart.

Use strict analysis options.

Zero analyzer warnings.

Zero lints.

---

# Native Style

Android:

Official Kotlin Style Guide

Apple:

Swift API Design Guidelines

Windows:

Modern C++

Linux:

Modern C++

---

# Feature Roadmap

Priority order:

1. Core runtime

2. Platform interface

3. Android Foreground Service

4. Download Engine

5. Notification Manager

6. Media Playback

7. Persistence

8. iOS

9. macOS

10. Windows

11. Linux

12. Web

13. Plugin Examples

14. Performance Optimization

15. Public Release

Do not skip roadmap stages.

---

# Definition of Done

A feature is complete only if:

✓ Compiles

✓ Tested

✓ Documented

✓ No lints

✓ Production-ready

✓ No TODOs

✓ No placeholder logic

✓ Cross-platform API maintained

If any item is missing, the feature is not complete.

---

# Monorepo Management

## Makefile

Use `make` for common operations from the repo root:

```bash
make            # get + analyze + test
make analyze    # dart analyze (workspace)
make test       # test platform_interface + app package
make clean      # remove build artifacts
make outdated   # check outdated deps
```

## Shell Scripts

- `tool/publish.sh` — Publish all packages to pub.dev in dependency order. Supports `--dry-run`.
- `tool/version.sh <version>` — Bump version across all 8 packages and update inter-package constraints. Example: `./tool/version.sh 0.2.0`.

## CI Workflows

- `.github/workflows/ci.yml` — Runs on push/PR to main. Jobs: analyze, test matrix (platform_interface + app), SwiftPM (iOS + macOS), CMake (Windows + Linux), Android build.
- `.github/workflows/publish.yml` — Manual dispatch or release-triggered publishing with dry-run support. Requires `PUB_CREDENTIALS` secret.

## Publish Order

Always publish in dependency order:

1. `background_runtime_platform_interface`
2. `background_runtime_android`
3. `background_runtime_ios`
4. `background_runtime_macos`
5. `background_runtime_windows`
6. `background_runtime_linux`
7. `background_runtime_web`
8. `background_runtime`
