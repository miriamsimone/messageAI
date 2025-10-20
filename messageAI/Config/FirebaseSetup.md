# Firebase Setup Checklist

1. Download `GoogleService-Info.plist` for the **messageAI** app from the Firebase Console.
2. Place the file at `messageAI/Resources/GoogleService-Info.plist`. (The root repository already ignores this path.)
3. Add the following SDKs via Swift Package Manager or CocoaPods:
   - `FirebaseAuth`
   - `FirebaseFirestore`
   - `FirebaseStorage`
   - `FirebaseMessaging`
4. Verify `FirebaseConfig.configure()` is called during application launch (already wired in `App/AppDelegate.swift`).
5. Confirm Firestore and Storage security rules are configured for the MVP contexts.
6. Configure APNs key/certificate in Firebase for push notifications when ready.

> Tip: keep the `.example` file as a reminder and never commit the real `GoogleService-Info.plist`.

