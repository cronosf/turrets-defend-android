# Publishing a release

The app checks `https://api.github.com/repos/cronosf/turrets-defend-android/releases/latest`
on launch (`lib/services/update_checker.dart`) and prompts players to update when the
latest release tag is newer than `kAppVersion` (`lib/app_version.dart`). Publishing a
release means: bump the version, build a release APK, and create a GitHub Release with
that APK attached.

## 1. Bump the version

- `lib/app_version.dart`: `kAppVersion` — bump the patch digit by 0.1 (e.g. `v1.0.39` -> `v1.0.40`).
- `pubspec.yaml`: `version:` — same patch bump, plus +1 on the build number after the `+`
  (e.g. `1.0.39+40` -> `1.0.40+41`).

## 2. Build

```
flutter analyze
flutter test test/widget_test.dart
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`.

Rename/copy it to match the existing asset naming convention before uploading:
`TurretCron-v{version}.apk` (e.g. `TurretCron-v1.0.40.apk`).

## 3. Publish via GitHub CLI (`gh`)

`gh` is not installed or authenticated by default on a fresh machine/environment. If
`gh auth status` doesn't show a logged-in account:

```
winget install --id GitHub.cli --accept-source-agreements --accept-package-agreements -e
gh auth login --hostname github.com --git-protocol https --web
```

The login prints a one-time device code and `https://github.com/login/device` — open
that URL, enter the code, and authorize. Once `gh auth status` shows logged in, this
persists on that machine (stored in Windows Credential Manager), so it's a one-time
setup per machine, not per release.

Then create the release:

```
gh release create v{version} \
  "build/app/outputs/flutter-apk/TurretCron-v{version}.apk" \
  --repo cronosf/turrets-defend-android \
  --title "v{version}" \
  --notes "..."
```

Tag format is `vX.Y.Z` (`UpdateChecker._parse` strips the leading `v`). Release notes
are shown to players in-app — keep them short, non-technical, and in Spanish (no
mentions of the PHP backend, database, or anything implementation-specific).

## Asset-staging pitfall

`assets/` has several raw/unprocessed source-art folders at the top level —
`assets/bosses/`, `assets/core_sprites/`, `assets/items/`, `assets/logros/`,
`assets/mobs/` (purchased kit originals: `.ai`/`.eps` files, full unused animation
sequences, ~700MB combined) — that are **not** referenced by `pubspec.yaml` and must
never be committed. Only `assets/images/...` is real, shipped app content. These raw
folders are covered by `.gitignore`, but double-check `git status` / `git diff --stat`
before any `git add -A` or wildcard add — a raw source folder and its processed
`assets/images/...` counterpart can look similar enough to add by mistake.
