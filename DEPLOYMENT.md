# Firebase Deployment Guide

This guide walks you through deploying Firestore rules, Storage rules, and indexes to your Firebase project.

## Prerequisites

1. **Firebase CLI**: Install if you haven't already:
   ```bash
   npm install -g firebase-tools
   ```

2. **Firebase Project**: Ensure you have a Firebase project set up.

3. **Firebase Login**: Authenticate with Firebase:
   ```bash
   firebase login
   ```

## Initial Setup

### 1. Initialize Firebase (if not already done)

If this is your first time deploying, initialize Firebase in the project:

```bash
cd /Users/miriam/Desktop/messageAI
firebase init
```

When prompted:
- Select **Firestore** and **Storage**
- Choose **Use an existing project** and select your Firebase project
- Accept the default file names (firestore.rules, firestore.indexes.json, storage.rules)
- **Do NOT overwrite** the existing files when asked

### 2. Set Your Firebase Project

```bash
firebase use --add
```

Select your project and give it an alias (e.g., "production" or "default").

## Deployment Steps

### Deploy Everything

To deploy all rules and indexes at once:

```bash
firebase deploy
```

### Deploy Individually (Optional)

If you prefer to deploy specific components:

**Deploy Firestore rules only:**
```bash
firebase deploy --only firestore:rules
```

**Deploy Firestore indexes only:**
```bash
firebase deploy --only firestore:indexes
```

**Deploy Storage rules only:**
```bash
firebase deploy --only storage
```

## What's Being Deployed

### Firestore Security Rules (`firestore.rules`)

Protects your Firestore data with the following rules:

- **Users Collection**: Users can read all profiles but only write their own
- **Conversations Collection**: Only participants can access conversation data
- **Messages Subcollection**: Only participants can read/write messages
- **Typing Indicators**: Only participants can see/update typing status
- **Presence Collection**: Users can read all presence, write only their own

### Storage Security Rules (`storage.rules`)

Protects your Firebase Storage with:

- **Conversation Media** (`conversations/{id}/media/{file}`):
  - Only participants can upload/download
  - Max 10MB per file
  - Only media types (image/video/audio)
  
- **User Profile Pictures** (`users/{userId}/profile/{file}`):
  - Anyone authenticated can read
  - Only the user can upload/update their own
  - Max 5MB per file
  - Only images
  
- **Group Avatars** (`conversations/{id}/avatar/{file}`):
  - Only participants can upload/download
  - Max 2MB per file
  - Only images

### Firestore Indexes (`firestore.indexes.json`)

Creates composite indexes for efficient queries:

1. **Conversations by Participant + Timestamp**
   - Query: Filter by participant array, sort by lastMessageTimestamp
   - Used for: Conversation list ordered by most recent message

2. **Messages by Timestamp**
   - Query: Sort messages by timestamp
   - Used for: Displaying messages in chronological order

## Verify Deployment

### 1. Check Firestore Rules

Go to [Firebase Console](https://console.firebase.google.com) → Your Project → Firestore Database → Rules

You should see the rules deployed with a recent timestamp.

### 2. Check Storage Rules

Go to Firebase Console → Your Project → Storage → Rules

You should see the storage rules with conversation media, profile pictures, and avatar paths.

### 3. Check Indexes

Go to Firebase Console → Your Project → Firestore Database → Indexes

You should see:
- A composite index on `conversations` (participants + lastMessageTimestamp)
- A single-field index on `messages` (timestamp)

**Note**: Indexes may take a few minutes to build. Check the "Status" column for completion.

## Firebase Storage Setup

### Enable Firebase Storage

1. Go to Firebase Console → Your Project → Storage
2. Click "Get Started"
3. Choose "Start in production mode" (rules are already configured)
4. Select a location (choose one close to your users)
5. Click "Done"

### Default Bucket

Your default bucket will be named: `{project-id}.appspot.com`

The app automatically uses this default bucket, so no additional configuration is needed.

### Storage Package

FirebaseStorage is already included in the Firebase iOS SDK. Verify in your Xcode project:
1. Open `messageAI.xcodeproj`
2. Select the project → messageAI target → Frameworks, Libraries, and Embedded Content
3. Ensure `FirebaseStorage` is listed (it should be automatically included via SPM)

## Testing

### Test Firestore Rules

Try these operations in your app:

1. **✅ Should succeed**: Read conversations you're a participant in
2. **✅ Should succeed**: Send a message in your conversation
3. **❌ Should fail**: Try to access another user's private conversation
4. **❌ Should fail**: Try to modify another user's profile

### Test Storage Rules

Try these operations:

1. **✅ Should succeed**: Upload a profile picture to your own profile
2. **✅ Should succeed**: Upload media to a conversation you're in
3. **❌ Should fail**: Upload a 20MB file (exceeds limits)
4. **❌ Should fail**: Upload to another user's profile path

### Test Indexes

Monitor the Xcode console when:

1. Loading conversation list (should be fast, no index warnings)
2. Loading messages in a chat (should be fast, no warnings)

If you see errors like "The query requires an index", Firebase will provide a direct link to create the missing index.

## Troubleshooting

### Issue: "Missing or insufficient permissions"

**Solution**: Check that:
- Your Firestore rules deployed correctly
- Your user is authenticated (`request.auth != null`)
- Your user is a participant in the conversation

### Issue: "The query requires an index"

**Solution**: 
1. Click the link in the error message (it will open Firebase Console)
2. The console will auto-create the required index
3. Wait for the index to build (may take a few minutes)
4. Retry your query

### Issue: "Storage upload fails"

**Solution**: Check that:
- Storage is enabled in Firebase Console
- Storage rules deployed correctly
- File size is within limits (10MB for media, 5MB for profiles, 2MB for avatars)
- File type is allowed (images, videos, audio for media; images only for profiles/avatars)

### Issue: "Firebase initialization fails"

**Solution**:
- Ensure `GoogleService-Info.plist` is in the project
- Rebuild the app (⌘+B)
- Clean build folder (⌘+Shift+K)

## Maintenance

### Updating Rules

When you modify `firestore.rules` or `storage.rules`:

1. Test locally if possible (Firebase Emulator Suite)
2. Deploy to staging/development first if you have multiple environments
3. Deploy to production:
   ```bash
   firebase deploy --only firestore:rules
   firebase deploy --only storage
   ```

### Adding New Indexes

If you encounter "query requires an index" errors:

1. Click the link in the error (opens Firebase Console)
2. Click "Create Index"
3. Wait for it to build
4. Add the index to `firestore.indexes.json` for version control
5. Commit the change to git

### Monitoring

Regularly check Firebase Console for:
- **Usage**: Firestore reads/writes, Storage bandwidth
- **Security**: Failed rule violations (potential attacks)
- **Performance**: Slow queries that need optimization

## Production Checklist

Before going live:

- [ ] Firestore rules deployed
- [ ] Storage rules deployed
- [ ] Indexes created and built
- [ ] Storage enabled with default bucket
- [ ] Rules tested with actual app
- [ ] Security rules prevent unauthorized access
- [ ] File size limits appropriate
- [ ] Indexes cover all common queries
- [ ] Monitor set up for errors
- [ ] Backup strategy in place

## Additional Resources

- [Firestore Security Rules Documentation](https://firebase.google.com/docs/firestore/security/get-started)
- [Storage Security Rules Documentation](https://firebase.google.com/docs/storage/security/start)
- [Firestore Indexes Documentation](https://firebase.google.com/docs/firestore/query-data/indexing)
- [Firebase CLI Reference](https://firebase.google.com/docs/cli)

---

**Questions?** Check the Firebase Console logs or reach out to the Firebase community.

