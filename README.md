# Manganite

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/Lyranile/manganite/main/system_files/usr/share/icons/hicolor/scalable/apps/manganite.svg">
  <source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/Lyranile/manganite/main/system_files/usr/share/icons/hicolor/scalable/apps/manganite.svg">
  <img alt="Manganite" src="https://raw.githubusercontent.com/Lyranile/manganite/main/system_files/usr/share/icons/hicolor/scalable/apps/manganite.svg" width="128">
</picture>

[![Build](https://github.com/Lyranile/manganite/actions/workflows/build.yml/badge.svg)](https://github.com/Lyranile/manganite/actions/workflows/build.yml)
[![Lint](https://github.com/Lyranile/manganite/actions/workflows/lint.yml/badge.svg)](https://github.com/Lyranile/manganite/actions/workflows/lint.yml)
[![License: Apache-2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

**Manganite** is a minimal, cloud-native desktop operating system built on the [Universal Blue](https://universal-blue.org/) `base-main` image. It layers the [Umbriel](https://noctalia.dev/umbriel) Wayland compositor (nightly, from Terra) and the [Noctalia](https://noctalia.dev/) shell on top of a desktop-free Fedora base, giving you a tiling, keyboard-driven desktop with near-zero maintenance.

🌐 **Packages:**
- With NVIDIA: [`ghcr.io/lyranile/manganite:latest`](https://github.com/Lyranile/manganite/pkgs/container/manganite)
- Without NVIDIA: [`ghcr.io/lyranile/manganite-no-nvidia:latest`](https://github.com/Lyranile/manganite-no-nvidia/pkgs/container/manganite-no-nvidia)

## Mission

Manganite's mission is to provide a small, reliable, and hackable desktop operating system for people who want a tiling Wayland compositor without the weight of a full desktop environment. We aim to deliver:

- **Minimalism**: A desktop-free base with only what you need to work and play.
- **Reliability**: Atomic, image-based updates via `bootc` / `rpm-ostree`, so your system stays consistent and rollback is always one command away.
- **Tiling-first UX**: Umbriel as the compositor and Noctalia as the shell, tuned for keyboard-driven workflows.
- **Cloud-native delivery**: The whole OS is an OCI image. Rebasing, pinning, and reproducing your system is a container operation.

## Getting Started

### Installation

The easiest way to try Manganite is to install from a disk image produced by the [`build-disk.yml`](./.github/workflows/build-disk.yml) workflow. Trigger that workflow (or download the artifact from the latest run) to get an `anaconda-iso` installer, then boot it and follow the Anaconda installer. The installer switches the target system to `ghcr.io/lyranile/manganite:latest` in place.

> **Note:** A hosted ISO download link and a project website are not published yet. See [Information needed](#information-needed) below.

### Rebase from an existing bootc system

Two variants are published:

- **With NVIDIA (open driver):** `ghcr.io/lyranile/manganite:latest`
- **Without NVIDIA:** `ghcr.io/lyranile/manganite-no-nvidia:latest`

If you already run a `bootc`-based system (Bazzite, Bluefin, Aurora, Fedora Atomic, or another Universal Blue image), you can switch to Manganite in place:

```bash
# With NVIDIA
sudo bootc switch ghcr.io/lyranile/manganite:latest

# Without NVIDIA
sudo bootc switch ghcr.io/lyranile/manganite-no-nvidia:latest

# Reboot to apply
sudo systemctl reboot
```

To mutate in place without queuing a separate deployment:

```bash
sudo bootc switch --mutate-in-place --transport registry ghcr.io/lyranile/manganite:latest
sudo systemctl reboot
```

After rebooting, confirm the running image:

```bash
sudo bootc status
```

### Roll back

If something goes wrong, roll back to the previous deployment at any time:

```bash
sudo bootc rollback
sudo systemctl reboot
```

### Rebase back to another image

You can leave Manganite the same way you arrived — just switch to any other `bootc` image:

```bash
sudo bootc switch ghcr.io/ublue-os/bluefin:stable
sudo systemctl reboot
```

## What's included

- **Base**: Universal Blue `base-main` (Fedora 44, desktop-free).
- **Compositor**: Umbriel (nightly, from Terra) + `xdg-desktop-portal-umbriel`.
- **Shell**: Noctalia (with `noctalia-greeter` on `greetd`).
- **Terminal / tools**: Ghostty, Yazi, Zsh (with Zinit), Starship, fastfetch, eza, bat, fzf, zoxide, just, go-task, and more.
- **GUI apps** (Flatpak, from Flathub): Waterfox, Zed, LibreOffice, Pinta, and a curated set of GNOME utilities.
- **Graphics**: NVIDIA proprietary akmods with a pinned kernel (see [NVIDIA](#nvidia)).
- **Updates**: `rpm-ostreed-automatic.timer`, `flatpak-system-update.timer`, and `flatpak-user-update.timer` enabled by default.

## Secure Boot

Secure Boot is supported using the Universal Blue signing key. After the first installation you will be prompted to enroll the key in your BIOS.

Enter the password `universalblue` when prompted.

If you skip that step, enroll manually:

```bash
sudo mokutil --timeout -1
sudo mokutil --import public_key.der
```

The public key is available from the akmods repository: <https://github.com/ublue-os/akmods/raw/main/certs/public_key.der>

If your image ships `ujust`, you can also run:

```bash
ujust enroll-secure-boot-key
```

## NVIDIA

The default build enables the proprietary NVIDIA stack (`NVIDIA_VARIANT="proprietary"`). It layers prebuilt open NVIDIA akmods and pins the kernel to the version the modules were built against, so do not upgrade the kernel independently. To build a plain (no-NVIDIA) image, set `NVIDIA=false` / `NVIDIA_VARIANT="none"` before building.

## Building locally

See the [Justfile](./Justfile) and the [original template documentation](#repository-contents) for build recipes. Quick start:

```bash
just build
sudo just build   # rootful, for rebasing locally
```

## Repository contents

- [Containerfile](./Containerfile) — image build entrypoint.
- [build_files/](./build_files/) — build scripts (shared + base).
- [system_files/](./system_files/) — files overlaid onto the image.
- [disk_config/](./disk_config/) — bootc-image-builder configs for ISO/qcow2/raw.
- [Justfile](./Justfile) — local build/run recipes.

## Community

- [Universal Blue Forums](https://universal-blue.discourse.group/)
- [Universal Blue Discord](https://discord.gg/8RZGC3uFzA)
- [bootc discussion forums](https://github.com/bootc-dev/bootc/discussions)
- Issues: <https://github.com/Lyranile/manganite/issues>

## Contributing

Contributions are welcome. Please open an issue or pull request on GitHub. This project follows the [Universal Blue Community Guidelines](https://universal-blue.org/contributing.html).

## License

This project is licensed under the Apache License 2.0 — see the [LICENSE](LICENSE) file for details.

### Third-party components

Manganite builds upon several open source projects:

- **Fedora Linux** — base operating system foundation
- **Universal Blue** — cloud-native desktop infrastructure (`base-main`)
- **Umbriel** — Wayland compositor
- **Noctalia** — desktop shell
- **Various CNCF / Flatpak projects** — cloud-native tooling and applications

All incorporated components maintain their respective licenses and attributions.

## Information needed

The following are not yet available and are needed to finish the public-facing documentation. Please provide them and I'll wire them in:

- **ISO download link** — a hosted URL for the `anaconda-iso` produced by `build-disk.yml` (or confirmation to use GitHub Actions artifacts only).
- **Project website** — if one exists (e.g. `getmanganite.dev`), for an install/scene picker like Aurora/Bluefin.
- **Screenshots / hero image** — a desktop screenshot for the README and docs.
- **Cosign public key hosting** — confirmation that `cosign.pub` stays in-repo (already present) is sufficient.
- **Supported architectures** — amd64 only, or arm64 too (the disk workflow already supports both).
- **Release channels** — whether `latest` is the only tag, or `stable`/dated tags should be documented.
- **ArtifactHub repository ID** — to finish [`artifacthub-repo.yaml`](./artifacthub-repo.yaml).
- **Contact / maintainer info** — for the README and Code of Conduct.
- **Noctalia/Umbriel upstream links** — canonical docs URLs for the compositor and shell.

---

Made with [Universal Blue](https://universal-blue.org/) and [bootc](https://github.com/bootc-dev/bootc).
