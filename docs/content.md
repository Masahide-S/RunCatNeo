:::header

# RunCat Neo

Cat living in the menubar.
:::

The cat tells you the CPU usage of your Mac by how fast it runs — one glance at the menu bar is all it takes.

![RunCat Neo demo](./images/demo.gif =480x)

[![Download on the App Store](./images/download_on_app_store_en.svg)](https://apps.apple.com/us/app/runcat-neo/id6757801838)

Requires macOS 26 or later · [View on GitHub](https://github.com/runcat-dev/RunCatNeo)

## Features

~ | [~speed] | [~metrics] | [~light] |
~ | :--- | :--- | :--- |

:::warp speed

### 🐈 Load at a glance

The cat speeds up as your CPU gets busier and slows to a stroll when things are calm. No numbers to read — just watch it run.
:::

:::warp metrics

### 📊 Custom Metrics

Point RunCat at any local JSON file and it becomes a live card on the dashboard. CPU, memory, and anything else you care to track.
:::

:::warp light

### 🪶 Light & native

Built for modern macOS in Swift. It lives quietly in the menu bar and sips system resources while it runs.
:::

## Custom Metrics

Beyond CPU, RunCat Neo can watch a JSON file you maintain and render it as a card — refreshed the moment the file changes, with no polling and no network calls. Track Claude Code usage, GPU temperature, a Bitcoin price, GitHub contributions — anything you can write to a file.

- [JSON schema reference](https://github.com/runcat-dev/RunCatNeo/blob/main/docs/CustomMetricsSchema.md)
- [Claude Code statusLine sample](https://github.com/runcat-dev/RunCatNeo/tree/main/docs/samples/claude-code)
- [Bitcoin price sample](https://github.com/runcat-dev/RunCatNeo/tree/main/docs/samples/bitcoin)

## FAQ

:::details What does the running cat actually show?
The cat's running speed reflects your Mac's CPU usage in real time. When the system is idle it walks slowly; under heavy load it sprints. It is a calm, ambient way to feel how busy your machine is without reading any numbers.
:::

:::details How do I install it?
RunCat Neo is distributed through the Mac App Store and requires macOS 26 or later. [Download it here](https://apps.apple.com/us/app/runcat-neo/id6757801838).
:::

:::details What languages does it support?
RunCat Neo is available in ten languages: English, Japanese, Chinese (Simplified), Chinese (Traditional), Korean, French, German, Spanish, Russian, and Vietnamese.
:::

:::details What are Custom Metrics?
A Custom Metric is any local JSON file written in the [documented format](https://github.com/runcat-dev/RunCatNeo/blob/main/docs/CustomMetricsSchema.md). You keep the file up to date with a small script, and RunCat watches it with filesystem events and renders it as a card the instant it changes. See the [ready-made samples](https://github.com/runcat-dev/RunCatNeo/tree/main/docs/samples) to get started.
:::

:::details Is this the same as the original RunCat?
No. RunCat Neo is a next-generation RunCat, newly built for modern macOS. It is not a replacement or upgrade of the existing RunCat, but a fresh take on the concept.
:::

:::details Where do I report a bug or request a feature?
Open an Issue on the [GitHub repository](https://github.com/runcat-dev/RunCatNeo) following the template. For contributor discussion, the [RunCat Developers community](https://runcat-dev.github.io) is the place to be.
:::

:::footer
[Privacy Policy](./privacy_policy.html) · [GitHub](https://github.com/runcat-dev/RunCatNeo) · [RunCat Developers](https://runcat-dev.github.io)

**English** · [日本語](./?lang=ja)

© 2026 Takuto Nakamura (Kyome22)
:::
