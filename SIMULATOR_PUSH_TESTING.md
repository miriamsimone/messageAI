# Simulator Push Testing

Use this flow to preview push notification handling without an Apple Developer account or real APNs credentials.

## Send a Local Push
- Boot the desired iOS simulator in Xcode or with `xcrun simctl boot`.
- From the repository root run:
  ```
  xcrun simctl push booted ai.gauntlet.miriam-messageAI tools/push/local-message.apns
  ```
- Update `conversationId` in `tools/push/local-message.apns` to match a real conversation document ID when you want to deep-link into an existing thread.

## Expectations
- The push should appear as an in-app banner (sound optional) when the app is foregrounded.
- Tapping the notification routes to the matching chat once the user is signed in; if the conversation isn't cached yet the list reloads automatically.
- The banner uses the payload's `aps.alert.title` and `aps.alert.body` fields, so edit them in the `.apns` file for different scenarios.

## Troubleshooting
- If nothing shows, confirm the simulator is running iOS 16.4 or later—the local push command won’t deliver on older runtimes.
- Run `Settings → Notifications → messageAI` inside the simulator to verify permission status; if prompts were denied, re-enable banners there.
- Check Xcode logs for `NotificationService` messages about authorization or device token registration when debugging.
