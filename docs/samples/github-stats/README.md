# GitHub Statistics Integration

A Python script that tracks your GitHub contribution activity in RunCat Neo. Shows your daily commits and weekly progress at a glance.

## Features

- **Today's commits** - How active you've been today
- **Recent days** - Up to 2 of the most recent prior days with contributions
- **This week's commits** - Weekly progress with a visual bar

## Setup

### 1. Install and authenticate GitHub CLI

```bash
# Install if you haven't already
brew install gh

# Authenticate (if not already done)
gh auth login
```

That's it! The script uses your existing GitHub CLI authentication - no tokens to manage.

### 2. Install the script

```bash
cp update-github-stats.py ~/.runcat/update-github-stats.py
chmod +x ~/.runcat/update-github-stats.py
```

### 3. Test it

```bash
~/.runcat/update-github-stats.py
python3 -m json.tool ~/.runcat/github-stats.json
```

You should see your GitHub stats in the JSON output.

### 4. Set up automatic updates

Copy the launchd configuration:

```bash
cp dev.runcat.github-stats.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/dev.runcat.github-stats.plist
```

This runs the script:
- Every 10 minutes (600 seconds)
- Automatically on login
- In the background

### 5. Add to RunCat Neo

1. Open **RunCat Neo → Settings → Metrics → Custom Metrics**
2. Click **"Add JSON Source"**
3. Select `~/.runcat/github-stats.json`
4. The card appears on your dashboard immediately

### Optional: Show in Menu Bar

Click the Metrics Bar icon and toggle the GitHub stats source to show your today's commit count directly in the menu bar.

### A note on "Today"

The script queries GitHub with timestamps in the Mac's local timezone, so day boundaries (what counts as "today" vs. "yesterday") match what you see on your own contribution graph on github.com. If the Mac running the script is in a different timezone than your GitHub account's, the two won't line up — there's no API-exposed account timezone setting to match against, only the querying machine's clock.

## Customization

Edit the script to adjust:
- **`metricsBarValue`** - Currently shows today's commits; change to week count instead
- **Metric normalization** - Line 244 normalizes weekly commits to max 100; adjust as needed
- **SF Symbol** - Line 249 uses `chevron.left.forwardslash.chevron.right`; pick any [SF Symbol](https://developer.apple.com/sf-symbols/)

## Troubleshooting

**"Error: GitHub CLI (gh) not found"**
- Install it with: `brew install gh`

**"Error getting GitHub credentials"**
- Make sure you're logged in: `gh auth login`
- Check your auth status: `gh auth status`

**"GitHub API error"**
- Your GitHub CLI session may have expired - re-authenticate with `gh auth login`

**Card shows old data**
- Check if the script is running: `launchctl list | grep github-stats`
- View logs: `log show --predicate 'process == "update-github-stats.py"' --last 1h`
- Run manually to see errors: `~/.runcat/update-github-stats.py`

**Card updates when run by hand, but not automatically**
- `launchctl print gui/$(id -u)/dev.runcat.github-stats` and check `last exit code`. A non-zero code with `gh command failed` or `GitHub CLI (gh) not found` means launchd couldn't find `gh` — its default `PATH` (`/usr/bin:/bin:/usr/sbin:/sbin`) doesn't include Homebrew's `bin` directory, even though your interactive shell's does.
- The bundled plist sets `EnvironmentVariables` → `PATH` to include `/opt/homebrew/bin` (Apple Silicon) and `/usr/local/bin` (Intel) for this reason. If you installed `gh` somewhere else, run `which gh` and add that directory too.
- After editing the plist, reload it: `launchctl bootout gui/$(id -u)/dev.runcat.github-stats; launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/dev.runcat.github-stats.plist`

**Rate limiting**
- Authenticated requests get 5,000 requests/hour (plenty for this use case)
- The script makes 2 GraphQL queries per run (plus one REST call for your username)
- Running every 10 minutes = 144 runs/day = ~432 API calls/day (well under limit)
