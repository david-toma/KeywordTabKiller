# Keyword Tab Killer

iOS host app + Safari Web Extension (Manifest V3). Closes the active Safari tab (`browser.tabs.remove`)
as soon as its URL or search query contains a blocked word. Words are managed in the app and shared with
the extension through the App Group `group.com.keywordblocker.shared` via native messaging.

## Build (no Mac needed)
1. Push this repo to GitHub (branch `main`).
2. **Actions → Build IPA** runs automatically; download `KeywordBlocker-ipa` from the run's artifacts.
3. For a release: `git tag v1.0.0 && git push origin v1.0.0` — the IPA is attached to the GitHub Release.

## Install via AltStore / SideStore
1. Repo **Settings → Pages**: deploy from branch `main`, folder `/docs`.
2. Replace `USERNAME` / `REPO` in `docs/source.json`.
3. Open `https://USERNAME.github.io/REPO/` on your iPhone and tap **Add to AltStore**.
4. Install **Keyword Tab Killer** from the source.

## Enable the extension
Settings → Safari → Extensions (iOS 18+: Settings → Apps → Safari → Extensions) → Keyword Tab Killer →
On → **All Websites: Allow**.

## Notes
- Free Apple IDs: the app + extension use 2 App IDs and must be refreshed every 7 days.
- `SharedStore.swift` reads the `ALTAppGroups` Info.plist key, because AltStore/SideStore rename the App Group when re-signing.
- The workflow uses `ldid` to embed entitlements into the unsigned binaries so the sideloading tool can see the App Group.
