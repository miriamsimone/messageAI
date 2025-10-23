messageAI - MVP Task List
Project Structure
messageAI/
├── messageAI.xcodeproj
├── messageAI/
│   ├── App/
│   │   ├── messageAIApp.swift
│   │   ├── AppDelegate.swift
│   │   └── SceneDelegate.swift
│   ├── Models/
│   │   ├── User.swift
│   │   ├── Conversation.swift
│   │   ├── Message.swift
│   │   ├── TypingIndicator.swift
│   │   └── Contact.swift
│   ├── ViewModels/
│   │   ├── AuthViewModel.swift
│   │   ├── ConversationListViewModel.swift
│   │   ├── ChatViewModel.swift
│   │   ├── GroupChatViewModel.swift
│   │   ├── UserSearchViewModel.swift
│   │   └── ProfileViewModel.swift
│   ├── Views/
│   │   ├── Authentication/
│   │   │   ├── LoginView.swift
│   │   │   ├── SignUpView.swift
│   │   │   └── UsernameSetupView.swift
│   │   ├── Main/
│   │   │   ├── MainTabView.swift
│   │   │   ├── ConversationListView.swift
│   │   │   └── ConversationRowView.swift
│   │   ├── Chat/
│   │   │   ├── ChatView.swift
│   │   │   ├── MessageBubbleView.swift
│   │   │   ├── MessageInputView.swift
│   │   │   ├── TypingIndicatorView.swift
│   │   │   └── ChatHeaderView.swift
│   │   ├── Contacts/
│   │   │   ├── ContactsView.swift
│   │   │   ├── UserSearchView.swift
│   │   │   ├── ContactRowView.swift
│   │   │   └── UserProfileView.swift
│   │   ├── Groups/
│   │   │   ├── CreateGroupView.swift
│   │   │   ├── GroupMemberSelectionView.swift
│   │   │   └── AddGroupMembersView.swift
│   │   ├── Profile/
│   │   │   ├── ProfileEditView.swift
│   │   │   └── ProfileImagePicker.swift
│   │   └── Components/
│   │       ├── LoadingView.swift
│   │       ├── ErrorView.swift
│   │       ├── ImageViewer.swift
│   │       └── NetworkStatusBanner.swift
│   ├── Services/
│   │   ├── FirebaseService.swift
│   │   ├── AuthService.swift
│   │   ├── MessageService.swift
│   │   ├── ConversationService.swift
│   │   ├── UserService.swift
│   │   ├── StorageService.swift
│   │   ├── NotificationService.swift
│   │   ├── PresenceService.swift
│   │   └── SyncService.swift
│   ├── Persistence/
│   │   ├── LocalDataManager.swift
│   │   ├── MessageQueue.swift
│   │   └── CacheManager.swift
│   ├── Utilities/
│   │   ├── NetworkMonitor.swift
│   │   ├── ImageCompressor.swift
│   │   ├── DateFormatter+Extensions.swift
│   │   ├── String+Extensions.swift
│   │   └── Constants.swift
│   ├── Resources/
│   │   ├── GoogleService-Info.plist
│   │   ├── Assets.xcassets
│   │   └── Info.plist
│   └── Config/
│       └── FirebaseConfig.swift
├── Podfile
└── README.md

Phase 0: Project Setup & Configuration (Week 1)
Task 0.1: Create Xcode Project
Priority: P0
Estimated Time: 1 hour
Files Created:

messageAI.xcodeproj
messageAI/messageAIApp.swift
messageAI/Resources/Assets.xcassets
messageAI/Resources/Info.plist

Steps:

Create new iOS app in Xcode
Select SwiftUI as interface
Configure app bundle identifier
Set minimum iOS version to 17.0+
Create folder structure


Task 0.2: Firebase Project Setup
Priority: P0
Estimated Time: 2 hours
Files Created/Modified:

messageAI/Resources/GoogleService-Info.plist
Podfile
messageAI/Config/FirebaseConfig.swift

Steps:

Create Firebase project in Firebase Console
Add iOS app to Firebase project
Download GoogleService-Info.plist
Enable Firebase Authentication (Email/Password)
Create Firestore database
Set up Firestore security rules
Enable Firebase Storage
Enable Firebase Cloud Messaging
Install Firebase SDK via CocoaPods or SPM

Firestore Security Rules to Configure:
javascript// Basic rules for MVP - refine later
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    match /conversations/{conversationId} {
      allow read, write: if request.auth.uid in resource.data.participants;
    }
    match /messages/{messageId} {
      allow read, write: if request.auth != null;
    }
  }
}

Task 0.3: Install Dependencies & Configure Build Settings
Priority: P0
Estimated Time: 1 hour
Files Created/Modified:

Podfile (if using CocoaPods)
messageAI.xcodeproj/project.pbxproj
messageAI/Resources/Info.plist

Dependencies:

Firebase/Auth
Firebase/Firestore
Firebase/Storage
Firebase/Messaging
Firebase/Analytics (optional for MVP)

Info.plist Configurations:

Camera usage description
Photo library usage description
Push notification capabilities
Background modes (remote notifications)


Task 0.4: Create Base Models
Priority: P0
Estimated Time: 3 hours
Files Created:

messageAI/Models/User.swift
messageAI/Models/Conversation.swift
messageAI/Models/Message.swift
messageAI/Models/TypingIndicator.swift
messageAI/Models/Contact.swift

Implementation Details:

Make models conform to Codable for Firestore
Add SwiftData macros for local persistence
Include all fields from PRD data models
Add computed properties for display logic


Task 0.5: Create Utility Classes
Priority: P0
Estimated Time: 2 hours
Files Created:

messageAI/Utilities/Constants.swift
messageAI/Utilities/DateFormatter+Extensions.swift
messageAI/Utilities/String+Extensions.swift
messageAI/Utilities/NetworkMonitor.swift

Constants to Include:

Firebase collection names
Rate limit thresholds
Image compression settings
Message pagination limits


Phase 1: Authentication (Week 1-2)
Task 1.1: Create Authentication Service
Priority: P0
Estimated Time: 4 hours
Files Created:

messageAI/Services/FirebaseService.swift
messageAI/Services/AuthService.swift

Files Modified:

messageAI/Config/FirebaseConfig.swift

Implementation:

Firebase initialization
Sign up with email/password
Login with email/password
Logout
Auth state listener
Password reset
Error handling


Task 1.2: Create Auth ViewModel
Priority: P0
Estimated Time: 3 hours
Files Created:

messageAI/ViewModels/AuthViewModel.swift

Files Modified:

messageAI/Services/AuthService.swift

Implementation:

ObservableObject for auth state
Sign up flow logic
Login flow logic
Form validation
Error state management
Loading states


Task 1.3: Create Login View
Priority: P0
Estimated Time: 3 hours
Files Created:

messageAI/Views/Authentication/LoginView.swift

Files Modified:

messageAI/ViewModels/AuthViewModel.swift

UI Components:

Email text field
Password secure field
Login button
Sign up navigation link
Error message display
Loading indicator


Task 1.4: Create Sign Up View
Priority: P0
Estimated Time: 3 hours
Files Created:

messageAI/Views/Authentication/SignUpView.swift

Files Modified:

messageAI/ViewModels/AuthViewModel.swift

UI Components:

Email text field
Password secure field
Confirm password field
Display name field
Sign up button
Terms acceptance
Error message display


Task 1.5: Create Username Setup Flow
Priority: P0
Estimated Time: 4 hours
Files Created:

messageAI/Views/Authentication/UsernameSetupView.swift
messageAI/Services/UserService.swift

Files Modified:

messageAI/ViewModels/AuthViewModel.swift
messageAI/Models/User.swift

Implementation:

Username input field
Real-time username availability check
Username validation (alphanumeric, length)
Store username in Firestore
Create user document on signup
Ensure username uniqueness via Cloud Function or security rules


Task 1.6: Persist User Profile Document
Priority: P0
Estimated Time: 4 hours
Files Modified:

messageAI/Services/UserService.swift
messageAI/ViewModels/AuthViewModel.swift
messageAI/Services/AuthService.swift

Implementation:

Add service endpoint to upsert Firestore user profiles with display name, username, and email
Invoke profile persistence immediately after signup and username completion
Update local SwiftData cache to reflect remote profile data
Surface errors and retry guidance if profile creation fails


Task 1.7: Create Profile Image Picker
Priority: P0
Estimated Time: 3 hours
Files Created:

messageAI/Views/Profile/ProfileImagePicker.swift
messageAI/Services/StorageService.swift
messageAI/Utilities/ImageCompressor.swift

Files Modified:

messageAI/Views/Authentication/UsernameSetupView.swift

Implementation:

PHPickerViewController integration
Camera integration (UIImagePickerController)
Image compression
Upload to Firebase Storage
Update user profile picture URL


Task 1.8: Create Main App Entry Point
Priority: P0
Estimated Time: 2 hours
Files Modified:

messageAI/App/messageAIApp.swift

Files Created:

messageAI/Views/Main/MainTabView.swift

Implementation:

Check auth state on launch
Show LoginView if not authenticated
Show MainTabView if authenticated
Configure Firebase on app launch
Set up SwiftData model container


Phase 2: Local Persistence (Week 2)
Task 2.1: Set Up SwiftData Model Container
Priority: P0
Estimated Time: 3 hours
Files Modified:

messageAI/App/messageAIApp.swift
messageAI/Models/User.swift
messageAI/Models/Conversation.swift
messageAI/Models/Message.swift

Implementation:

Add @Model macros to models
Configure model container
Set up model context
Define relationships between models


Task 2.2: Create Local Data Manager
Priority: P0
Estimated Time: 4 hours
Files Created:

messageAI/Persistence/LocalDataManager.swift

Files Modified:

messageAI/Models/Message.swift
messageAI/Models/Conversation.swift

Implementation:

CRUD operations for messages
CRUD operations for conversations
Fetch queries with sorting/filtering
Pagination support
Batch operations


Task 2.3: Create Message Queue System
Priority: P0
Estimated Time: 5 hours
Files Created:

messageAI/Persistence/MessageQueue.swift

Files Modified:

messageAI/Persistence/LocalDataManager.swift
messageAI/Models/Message.swift

Implementation:

Queue unsent messages locally
Track message delivery status
Retry failed messages
Persist queue across app restarts
Remove messages from queue on success


Task 2.4: Create Cache Manager
Priority: P0
Estimated Time: 3 hours
Files Created:

messageAI/Persistence/CacheManager.swift

Implementation:

NSCache for in-memory image caching
Disk cache for persistent image storage
Cache eviction policies
Cache size limits
Image retrieval methods


Phase 3: User Discovery & Contacts (Week 2-3)
Task 3.1: Create User Search Service
Priority: P0
Estimated Time: 4 hours
Files Modified:

messageAI/Services/UserService.swift

Implementation:

Search users by username
Firestore query with username index
Case-insensitive search
Return search results
Paginate results if needed


Task 3.2: Create User Search ViewModel
Priority: P0
Estimated Time: 3 hours
Files Created:

messageAI/ViewModels/UserSearchViewModel.swift

Files Modified:

messageAI/Services/UserService.swift

Implementation:

Search query state
Search results state
Debounced search (avoid too many queries)
Loading state
Error handling


Task 3.3: Create User Search View
Priority: P0
Estimated Time: 4 hours
Files Created:

messageAI/Views/Contacts/UserSearchView.swift
messageAI/Views/Contacts/ContactRowView.swift

Files Modified:

messageAI/ViewModels/UserSearchViewModel.swift

UI Components:

Search bar
Search results list
User row (username, display name, profile pic)
Add to contacts button
Empty state
Loading indicator


Task 3.4: Implement Contact Management
Priority: P0
Estimated Time: 4 hours
Files Modified:

messageAI/Services/UserService.swift
messageAI/Models/User.swift

Implementation:

Add contact to user's contact list
Remove contact
Fetch user's contacts
Update Firestore user document
Handle contact privacy (profiles only visible to contacts)


Task 3.5: Create Contacts View
Priority: P0
Estimated Time: 3 hours
Files Created:

messageAI/Views/Contacts/ContactsView.swift

Files Modified:

messageAI/Views/Contacts/ContactRowView.swift
messageAI/Views/Main/MainTabView.swift

UI Components:

Contact list
Search button (navigate to UserSearchView)
Contact rows
Pull to refresh
Empty state


Task 3.6: Create User Profile View
Priority: P0
Estimated Time: 3 hours
Files Created:

messageAI/Views/Contacts/UserProfileView.swift

Files Modified:

messageAI/Services/UserService.swift

UI Components:

Profile picture
Display name
Username
Start chat button
Add/remove contact button (if not/already contact)
Privacy check (show limited info for non-contacts)


Phase 4: One-on-One Chat (Week 3)
Task 4.1: Create Conversation Service
Priority: P0
Estimated Time: 5 hours
Files Created:

messageAI/Services/ConversationService.swift

Implementation:

Create new conversation
Fetch user's conversations
Fetch conversation by ID
Update conversation metadata
Real-time conversation listener
Check if conversation exists between users


Task 4.2: Create Message Service
Priority: P0
Estimated Time: 6 hours
Files Created:

messageAI/Services/MessageService.swift

Implementation:

Send message (text)
Send message (image)
Fetch messages for conversation
Real-time message listener
Update message status (sent, delivered, read)
Paginate message history
Handle optimistic updates


Task 4.3: Create Conversation List ViewModel
Priority: P0
Estimated Time: 4 hours
Files Created:

messageAI/ViewModels/ConversationListViewModel.swift

Files Modified:

messageAI/Services/ConversationService.swift
messageAI/Persistence/LocalDataManager.swift

Implementation:

Fetch conversations from local DB
Sync with Firestore
Real-time updates
Sort by last message timestamp
Unread count calculation
Delete conversation


Task 4.4: Create Conversation List View
Priority: P0
Estimated Time: 4 hours
Files Created:

messageAI/Views/Main/ConversationListView.swift
messageAI/Views/Main/ConversationRowView.swift

Files Modified:

messageAI/ViewModels/ConversationListViewModel.swift
messageAI/Views/Main/MainTabView.swift

UI Components:

Conversation list
New chat button
Conversation rows (avatar, name, last message, timestamp, unread badge)
Swipe actions (delete)
Pull to refresh
Empty state


Task 4.5: Create Chat ViewModel
Priority: P0
Estimated Time: 6 hours
Files Created:

messageAI/ViewModels/ChatViewModel.swift

Files Modified:

messageAI/Services/MessageService.swift
messageAI/Services/ConversationService.swift
messageAI/Persistence/MessageQueue.swift

Implementation:

Load messages from local DB
Real-time message listener
Send message with optimistic update
Update message delivery status
Pagination (load older messages)
Mark messages as read
Handle offline message queueing


Task 4.6: Create Chat View
Priority: P0
Estimated Time: 6 hours
Files Created:

messageAI/Views/Chat/ChatView.swift
messageAI/Views/Chat/MessageBubbleView.swift
messageAI/Views/Chat/MessageInputView.swift
messageAI/Views/Chat/ChatHeaderView.swift

Files Modified:

messageAI/ViewModels/ChatViewModel.swift

UI Components:

Scrollable message list
Message bubbles (sent/received styling)
Message timestamps
Delivery status indicators (checkmarks)
Text input field
Send button
Image attachment button
Chat header (contact name, status)
Scroll to bottom button


Task 4.7: Implement Optimistic UI Updates
Priority: P0
Estimated Time: 4 hours
Files Modified:

messageAI/ViewModels/ChatViewModel.swift
messageAI/Services/MessageService.swift
messageAI/Persistence/LocalDataManager.swift
messageAI/Models/Message.swift

Implementation:

Generate local message ID
Insert message into local DB immediately
Show message in UI with "sending" status
Send to Firestore in background
Update local message with server ID and "sent" status
Handle send failures (show error, queue for retry)


Task 4.8: Implement Message Timestamps
Priority: P0
Estimated Time: 2 hours
Files Modified:

messageAI/Views/Chat/MessageBubbleView.swift
messageAI/Utilities/DateFormatter+Extensions.swift

Implementation:

Format timestamps (Today, Yesterday, full date)
Show timestamps in message bubbles
Group messages by date
Show relative time for recent messages


Phase 5: Presence & Typing Indicators (Week 4)
Task 5.1: Create Presence Service
Priority: P0
Estimated Time: 5 hours
Files Created:

messageAI/Services/PresenceService.swift

Implementation:

Update user online status
Listen to presence changes
Handle app lifecycle (foreground/background)
Update last seen timestamp
Firestore presence system with heartbeat
Clean up presence on disconnect


Task 5.2: Implement Online/Offline Indicators
Priority: P0
Estimated Time: 3 hours
Files Modified:

messageAI/Views/Chat/ChatHeaderView.swift
messageAI/Views/Main/ConversationRowView.swift
messageAI/Services/PresenceService.swift

UI Components:

Online indicator (green dot)
Last seen text (for offline users)
Real-time status updates


Task 5.3: Create Typing Indicator Service
Priority: P0
Estimated Time: 4 hours
Files Modified:

messageAI/Services/MessageService.swift

Files Created:

messageAI/Views/Chat/TypingIndicatorView.swift

Implementation:

Send typing indicator when user types
Listen to typing indicators from other users
Auto-expire typing indicator after 3 seconds
Firestore ephemeral typing status


Task 5.4: Implement Typing Indicator UI
Priority: P0
Estimated Time: 3 hours
Files Modified:

messageAI/Views/Chat/ChatView.swift
messageAI/ViewModels/ChatViewModel.swift
messageAI/Views/Chat/TypingIndicatorView.swift

UI Components:

Animated typing dots
"[User] is typing..." text
Show at bottom of message list
Handle multiple users typing (groups)


Phase 6: Read Receipts (Week 4)
Task 6.1: Implement Read Receipt Tracking
Priority: P0
Estimated Time: 4 hours
Files Modified:

messageAI/Services/MessageService.swift
messageAI/Models/Message.swift

Implementation:

Mark messages as read when viewed
Update readBy array in Firestore
Track read timestamps
Batch update for multiple messages


Task 6.2: Implement Read Receipt UI
Priority: P0
Estimated Time: 3 hours
Files Modified:

messageAI/Views/Chat/MessageBubbleView.swift
messageAI/ViewModels/ChatViewModel.swift

UI Components:

Double checkmark for read messages
Single checkmark for delivered
Gray for sent
Real-time updates


Task 6.3: Mark Messages as Read on View
Priority: P0
Estimated Time: 3 hours
Files Modified:

messageAI/ViewModels/ChatViewModel.swift
messageAI/Views/Chat/ChatView.swift

Implementation:

Detect when message appears on screen
Mark as read automatically
Update unread count
Batch read receipts (don't spam Firestore)


Phase 7: Network Resilience (Week 4)
Task 7.1: Implement Network Monitor
Priority: P0
Estimated Time: 3 hours
Files Modified:

messageAI/Utilities/NetworkMonitor.swift

Implementation:

Monitor network connectivity (Network framework)
Publish connectivity state
Detect connection type (WiFi, cellular, offline)
Monitor reachability changes


Task 7.2: Create Sync Service
Priority: P0
Estimated Time: 6 hours
Files Created:

messageAI/Services/SyncService.swift

Files Modified:

messageAI/Persistence/MessageQueue.swift
messageAI/Services/MessageService.swift
messageAI/Utilities/NetworkMonitor.swift

Implementation:

Monitor network status
Flush message queue when online
Sync pending messages
Sync read receipts
Handle conflicts (rare in chat apps)
Retry with exponential backoff


Task 7.3: Implement Network Status Banner
Priority: P0
Estimated Time: 2 hours
Files Created:

messageAI/Views/Components/NetworkStatusBanner.swift

Files Modified:

messageAI/Views/Chat/ChatView.swift
messageAI/Utilities/NetworkMonitor.swift

UI Components:

Red banner for offline
Yellow banner for poor connection
Auto-dismiss when online
Show in chat view and conversation list


Task 7.4: Implement Retry Logic for Failed Messages
Priority: P0
Estimated Time: 4 hours
Files Modified:

messageAI/ViewModels/ChatViewModel.swift
messageAI/Services/MessageService.swift
messageAI/Persistence/MessageQueue.swift

Implementation:

Detect failed sends
Show retry button in UI
Manual retry option
Automatic retry when back online
Exponential backoff for retries


Task 7.5: Handle App Lifecycle for Message Queue
Priority: P0
Estimated Time: 3 hours
Files Modified:

messageAI/App/messageAIApp.swift
messageAI/Services/SyncService.swift

Implementation:

Flush queue on app foreground
Pause sync on background
Handle app termination gracefully
Resume sync on relaunch


Phase 8: Group Chat (Week 5)
Task 8.1: Extend Conversation Service for Groups
Priority: P0
Estimated Time: 4 hours
Files Modified:

messageAI/Services/ConversationService.swift
messageAI/Models/Conversation.swift

Implementation:

Create group conversation
Add participants to group
Update group metadata (name, avatar)
Fetch group members
Support 3+ participants


Task 8.2: Create Group Chat ViewModel
Priority: P0
Estimated Time: 4 hours
Files Created:

messageAI/ViewModels/GroupChatViewModel.swift

Files Modified:

messageAI/ViewModels/ChatViewModel.swift

Implementation:

Reuse ChatViewModel logic for groups
Handle group-specific features
Track read receipts per member
Show member typing indicators


Task 8.3: Create Group Creation Flow
Priority: P0
Estimated Time: 5 hours
Files Created:

messageAI/Views/Groups/CreateGroupView.swift
messageAI/Views/Groups/GroupMemberSelectionView.swift

Files Modified:

messageAI/Views/Main/ConversationListView.swift

UI Components:

Member selection (multi-select from contacts)
Group name input
Group avatar picker
Create button
Member count (min 3)


Task 8.4: Implement Add Members to Existing Group
Priority: P0
Estimated Time: 3 hours
Files Created:

messageAI/Views/Groups/AddGroupMembersView.swift

Files Modified:

messageAI/Services/ConversationService.swift
messageAI/Views/Chat/ChatHeaderView.swift

Implementation:

Select additional members from contacts
Update group participants array
Notify new members
Allow any group member to add


Task 8.5: Implement Group Read Receipts
Priority: P0
Estimated Time: 4 hours
Files Modified:

messageAI/Views/Chat/MessageBubbleView.swift
messageAI/ViewModels/GroupChatViewModel.swift

UI Components:

Show avatars of members who read message
"Read by X" indicator
Tap to see full read list
Handle partial read states


Task 8.6: Implement Group Message Attribution
Priority: P0
Estimated Time: 2 hours
Files Modified:

messageAI/Views/Chat/MessageBubbleView.swift

UI Components:

Show sender name above message (for others' messages)
Show sender avatar
Don't show name/avatar for own messages


Phase 9: Media Sharing (Week 5)
Task 9.1: Implement Image Upload to Storage
Priority: P0
Estimated Time: 4 hours
Files Modified:

messageAI/Services/StorageService.swift
messageAI/Utilities/ImageCompressor.swift

Implementation:

Compress image before upload
Generate thumbnail
Upload to Firebase Storage
Get download URL
Handle upload progress
Error handling


Task 9.2: Implement Image Message Sending
Priority: P0
Estimated Time: 4 hours
Files Modified:

messageAI/Services/MessageService.swift
messageAI/ViewModels/ChatViewModel.swift
messageAI/Models/Message.swift

Implementation:

Upload image to Storage
Create message with image URL
Show upload progress
Handle upload failures
Queue image messages offline


Task 9.3: Create Image Picker Integration
Priority: P0
Estimated Time: 3 hours
Files Modified:

messageAI/Views/Chat/MessageInputView.swift

Implementation:

PHPickerViewController for photo library
Camera integration
Image selection UI
Preview before sending


Task 9.4: Implement Image Display in Chat
Priority: P0
Estimated Time: 4 hours
Files Modified:

messageAI/Views/Chat/MessageBubbleView.swift

Files Created:

messageAI/Views/Components/ImageViewer.swift

UI Components:

Image thumbnail in message bubble
Tap to view full-size
Loading placeholder
Failed load error state
Image caching


Task 9.5: Create Full-Screen Image Viewer
Priority: P0
Estimated Time: 3 hours
Files Modified:

messageAI/Views/Components/ImageViewer.swift

UI Components:

Full-screen image view
Pinch to zoom
Swipe to dismiss
Share button
Close button


Phase 10: Push Notifications (Week 5)
Task 10.1: Configure FCM in Firebase Console
Priority: P0
Estimated Time: 2 hours
Files Modified:

Firebase Console (web)
messageAI/Resources/Info.plist
Apple Developer Portal (APNs certificates)

Steps:

Upload APNs certificate to Firebase
Configure notification capabilities in Xcode
Enable push notifications in App ID


Task 10.2: Create Notification Service
Priority: P0
Estimated Time: 5 hours
Files Created:

messageAI/Services/NotificationService.swift

Files Modified:

messageAI/App/messageAIApp.swift

Implementation:

Request notification permissions
Register for remote notifications
Store FCM token in Firestore
Handle token refresh
Handle notification received (foreground)
Handle notification tap


Task 10.3: Create Cloud Function for Push Notifications
Priority: P0
Estimated Time: 6 hours
Files Created:

functions/index.js (Firebase Cloud Functions)
functions/package.json

Implementation:

Trigger on new message created
Fetch recipient FCM tokens
Send notification via FCM Admin SDK
Include sender name and message preview
Handle group chat notifications
Don't send to sender
Don't send if recipient is online and in chat


Task 10.4: Implement Foreground Notification UI
Priority: P0
Estimated Time: 3 hours
Files Modified:

messageAI/Services/NotificationService.swift
`messageAI/App/messageAIApp.swift`
UI Components:

Banner notification at top of screen
Show sender name and message preview
Tap to navigate to chat
Auto-dismiss after 3 seconds
Don't show if already in that chat


Task 10.5: Handle Notification Navigation
Priority: P0
Estimated Time: 3 hours
Files Modified:

messageAI/Services/NotificationService.swift
messageAI/Views/Main/MainTabView.swift
messageAI/App/messageAIApp.swift

Implementation:

Parse notification payload
Extract conversation ID
Navigate to chat view
Handle deep linking
Work for background and killed state


Task 10.6: Test Background & Killed State Notifications (Stretch)
Priority: P1 (Nice to have for MVP)
Estimated Time: 4 hours
Files Modified:

messageAI/Services/NotificationService.swift
messageAI/Resources/Info.plist

Implementation:

Enable background modes
Handle notification when app in background
Handle notification when app is killed
Update badge count
Test on physical device


Phase 11: Profile Management (Week 5)
Task 11.1: Create Profile ViewModel
Priority: P0
Estimated Time: 3 hours
Files Created:

messageAI/ViewModels/ProfileViewModel.swift

Files Modified:

messageAI/Services/UserService.swift

Implementation:

Load current user profile
Update display name
Update username (with validation)
Update profile picture
Logout functionality


Task 11.2: Create Profile Edit View
Priority: P0
Estimated Time: 4 hours
Files Created:

messageAI/Views/Profile/ProfileEditView.swift

Files Modified:

messageAI/Views/Main/MainTabView.swift
messageAI/ViewModels/ProfileViewModel.swift

UI Components:

Profile picture (tap to change)
Display name field
Username field
Email (read-only)
Save button
Logout button
Loading states


Phase 12: Error Handling & Loading States (Week 6)
Task 12.1: Create Reusable Error View
Priority: P0
Estimated Time: 2 hours
Files Created:

messageAI/Views/Components/ErrorView.swift

UI Components:

Error icon
Error message
Retry button
Dismiss button


Task 12.2: Create Loading View Component
Priority: P0
Estimated Time: 1 hour
Files Created:

messageAI/Views/Components/LoadingView.swift

UI Components:

Loading spinner
Optional loading message
Overlay for blocking UI


Task 12.3: Implement Error Handling Across ViewModels
Priority: P0
Estimated Time: 4 hours
Files Modified:

messageAI/ViewModels/AuthViewModel.swift
messageAI/ViewModels/ChatViewModel.swift
messageAI/ViewModels/ConversationListViewModel.swift
messageAI/ViewModels/UserSearchViewModel.swift
messageAI/ViewModels/ProfileViewModel.swift

Implementation:

Add error state properties
Catch and handle errors from services
Show user-friendly error messages
Provide retry mechanisms


Task 12.4: Implement Loading States Across Views
Priority: P0
Estimated Time: 3 hours
Files Modified:

messageAI/Views/Chat/ChatView.swift
messageAI/Views/Main/ConversationListView.swift
messageAI/Views/Contacts/UserSearchView.swift
messageAI/Views/Authentication/LoginView.swift

Implementation:

Show loading indicators during async operations
Disable buttons during loading
Show skeleton screens where appropriate


Phase 13: Testing & Bug Fixes (Week 6)
Task 13.1: Test Scenario 1 - Real-Time Two-Device Chat
Priority: P0
Estimated Time: 2 hours
Testing Steps:

Set up two iOS devices/simulators
Log in with different accounts
Send messages back and forth
Verify message delivery < 2 seconds
Verify correct message order
Test with text and image messages

Files to Monitor for Issues:

messageAI/Services/MessageService.swift
messageAI/ViewModels/ChatViewModel.swift
messageAI/Views/Chat/ChatView.swift


Task 13.2: Test Scenario 2 - Offline/Online Transition
Priority: P0
Estimated Time: 2 hours
Testing Steps:

Device A online, Device B enable airplane mode
Device A sends 5 messages
Device B disable airplane mode
Verify all 5 messages appear on Device B
Test message queue on sender side (A offline, send messages, go online)

Files to Monitor for Issues:

messageAI/Services/SyncService.swift
messageAI/Persistence/MessageQueue.swift
messageAI/Utilities/NetworkMonitor.swift


Task 13.3: Test Scenario 3 - Background Message Delivery
Priority: P0
Estimated Time: 2 hours
Testing Steps:

Device A: Background the app
Device B: Send message to A
Verify Device A receives notification
Tap notification and verify it opens correct chat
Verify message appears in chat

Files to Monitor for Issues:

messageAI/Services/NotificationService.swift
Cloud Functions notification trigger


Task 13.4: Test Scenario 4 - Persistence After Force-Quit
Priority: P0
Estimated Time: 2 hours
Testing Steps:

Open conversation with 20+ messages
Send a message
Force-quit app immediately
Reopen app
Verify all messages visible
Verify unsent message is in queue and sends

Files to Monitor for Issues:

messageAI/Persistence/LocalDataManager.swift
messageAI/Persistence/MessageQueue.swift
SwiftData model configuration


Task 13.5: Test Scenario 5 - Poor Network Conditions
Priority: P0
Estimated Time: 2 hours
Testing Steps:

Use Network Link Conditioner to simulate 3G
Send 10 messages rapidly
Verify all messages queue
Verify messages send eventually
Verify no message loss
Test with packet loss enabled

Files to Monitor for Issues:

messageAI/Services/MessageService.swift
messageAI/Persistence/MessageQueue.swift
messageAI/Services/SyncService.swift


Task 13.6: Test Scenario 6 - Rapid-Fire Messages
Priority: P0
Estimated Time: 2 hours
Testing Steps:

Two devices online
Send 20+ messages in quick succession
Verify all messages deliver
Verify correct order
Verify no duplicates
Check for race conditions

Files to Monitor for Issues:

messageAI/Services/MessageService.swift
messageAI/ViewModels/ChatViewModel.swift
Firestore transaction handling


Task 13.7: Test Scenario 7 - Group Chat (3+ Users)
Priority: P0
Estimated Time: 2 hours
Testing Steps:

Create group with 3 participants
All participants send messages
Verify all messages visible to all participants
Verify correct sender attribution
Test adding new member
Verify read receipts show correctly

Files to Monitor for Issues:

messageAI/Services/ConversationService.swift
messageAI/ViewModels/GroupChatViewModel.swift
messageAI/Views/Chat/MessageBubbleView.swift


Task 13.8: Test Scenario 8 - Username Search and Contact Discovery
Priority: P0
Estimated Time: 1 hour
Testing Steps:

Search for existing usernames
Verify search results are correct
Add contacts
Verify profile visibility (contacts vs non-contacts)
Test username uniqueness

Files to Monitor for Issues:

messageAI/Services/UserService.swift
messageAI/ViewModels/UserSearchViewModel.swift
Firestore security rules


Task 13.9: Test Scenario 9 - Rate Limiting
Priority: P0
Estimated Time: 1 hour
Testing Steps:

Send 150 messages rapidly within 60 seconds
Verify rate limit triggers after ~100 messages
Verify error message displays
Verify messages queue
Wait for limit to reset
Verify queued messages send

Files to Monitor for Issues:

Cloud Functions rate limiting logic
messageAI/Services/MessageService.swift
messageAI/ViewModels/ChatViewModel.swift


Task 13.10: Bug Fix Cycle 1
Priority: P0
Estimated Time: 8 hours
Files Modified: (Based on issues found in testing)
Common Issues to Address:

Message ordering issues
Race conditions in optimistic updates
Memory leaks in real-time listeners
Image caching problems
Notification delivery failures
UI state inconsistencies


Task 13.11: Bug Fix Cycle 2
Priority: P0
Estimated Time: 6 hours
Files Modified: (Based on issues found in testing)
Focus Areas:

Edge cases in group chat
Offline sync issues
Performance optimization
UI polish


Phase 14: Polish & Optimization (Week 6)
Task 14.1: Optimize Message Loading Performance
Priority: P1
Estimated Time: 3 hours
Files Modified:

messageAI/ViewModels/ChatViewModel.swift
messageAI/Services/MessageService.swift
messageAI/Views/Chat/ChatView.swift

Optimizations:

Implement efficient pagination
Lazy loading of images
Reduce Firestore reads
Optimize SwiftData queries


Task 14.2: Implement Empty States
Priority: P1
Estimated Time: 2 hours
Files Modified:

messageAI/Views/Main/ConversationListView.swift
messageAI/Views/Contacts/ContactsView.swift
messageAI/Views/Chat/ChatView.swift

UI Components:

Empty conversation list state
Empty contacts list state
Empty search results state
Helpful instructions for users


Task 14.3: Add Haptic Feedback
Priority: P2 (Nice to have)
Estimated Time: 2 hours
Files Modified:

messageAI/Views/Chat/MessageInputView.swift
messageAI/Views/Main/ConversationListView.swift

Implementation:

Send button tap feedback
Message received feedback
Swipe action feedback


Task 14.4: Improve Accessibility
Priority: P1
Estimated Time: 3 hours
Files Modified:

All View files

Implementation:

Add accessibility labels
Improve VoiceOver support
Test with Dynamic Type
Ensure proper contrast ratios


Task 14.5: Add Pull-to-Refresh
Priority: P1
Estimated Time: 2 hours
Files Modified:

messageAI/Views/Main/ConversationListView.swift
messageAI/Views/Contacts/ContactsView.swift

Implementation:

Pull to refresh conversation list
Pull to refresh contacts
Show loading indicator
Fetch latest data


Task 14.6: Memory Leak Testing
Priority: P0
Estimated Time: 3 hours
Files to Check:

All ViewModels (check for retain cycles)
messageAI/Services/MessageService.swift (listener cleanup)
messageAI/Services/PresenceService.swift (listener cleanup)
messageAI/Persistence/CacheManager.swift

Tools:

Xcode Instruments (Leaks)
Memory Graph Debugger


Task 14.7: App Icon and Launch Screen
Priority: P1
Estimated Time: 2 hours
Files Modified:

messageAI/Resources/Assets.xcassets/AppIcon.appiconset
messageAI/Resources/Assets.xcassets/LaunchScreen

Steps:

Design app icon
Create all required sizes
Create launch screen
Test on device


Phase 15: Deployment (Week 6)
Task 15.1: Configure Deployment Settings
Priority: P0
Estimated Time: 2 hours
Files Modified:

messageAI.xcodeproj/project.pbxproj
messageAI/Resources/Info.plist

Configuration:

Set version and build numbers
Configure signing & capabilities
Set deployment target
Configure release build settings
Disable debug logging in release


Task 15.2: TestFlight Setup
Priority: P1 (Preferred for MVP)
Estimated Time: 3 hours
Steps:

Archive app in Xcode
Upload to App Store Connect
Fill in test information
Add beta testers
Submit for TestFlight review
Distribute to testers

Files Modified:

App Store Connect (web)
Apple Developer Portal (web)


Task 15.3: Create Beta Testing Documentation
Priority: P1
Estimated Time: 2 hours
Files Created:

README.md (update)
TESTING_GUIDE.md
KNOWN_ISSUES.md

Content:

How to install via TestFlight
Features to test
How to report bugs
Known issues and limitations


Task 15.4: Deploy Firebase to Production
Priority: P0
Estimated Time: 2 hours
Steps:

Review Firestore security rules
Review Storage security rules
Deploy Cloud Functions
Set up Firebase budget alerts
Configure production environment variables
Test production Firebase connection

Files Modified:

firestore.rules
storage.rules
functions/index.js


Task 15.5: Final QA Pass
Priority: P0
Estimated Time: 4 hours
Testing:

Complete all 9 test scenarios again on production Firebase
Test on multiple iOS versions
Test on different device sizes (iPhone SE, Pro Max, iPad)
Verify all acceptance criteria met
Check for any visual bugs
Verify analytics tracking (if implemented)


Phase 16: Post-MVP (Future)
Task 16.1: Collect Beta Feedback
Priority: P1
Estimated Time: Ongoing
Activities:

Monitor crash reports in Firebase
Collect user feedback
Track analytics
Prioritize bug fixes
Plan next features


Task 16.2: Performance Monitoring Setup
Priority: P1
Estimated Time: 2 hours
Files Modified:

messageAI/App/messageAIApp.swift
Firebase Console

Implementation:

Enable Firebase Performance Monitoring
Add custom traces for critical paths
Monitor message send latency
Monitor image upload times


Summary Statistics
Total Estimated Time: ~240 hours (6 weeks at 40 hours/week)
File Count:

Models: 5 files
ViewModels: 6 files
Views: 25 files
Services: 9 files
Persistence: 3 files
Utilities: 5 files
Config: 1 file
Resources: 3 files
Cloud Functions: 1 project

Total Project Files: ~58 Swift files + supporting files

Critical Path Items (Must Complete for MVP)
✅ = MVP Blocker

✅ Firebase setup and configuration
✅ User authentication with username
✅ Username search and contacts
✅ Local persistence with SwiftData
✅ One-on-one chat with real-time delivery
✅ Optimistic UI updates
✅ Message queue for offline
✅ Network resilience
✅ Presence indicators
✅ Typing indicators
✅ Read receipts
✅ Group chat (3+ users)
✅ Image sharing
✅ Push notifications (foreground minimum)
✅ All 9 test scenarios passing
✅ Deployment to TestFlight or local with production backend


Notes for Implementation

Start with authentication - Nothing works without users
Build local persistence early - Foundation for offline support
One-on-one chat before groups - Simpler to debug
Test continuously - Don't wait until Week 6
Keep Cloud Functions simple - Just notifications and rate limiting for MVP
Use Firebase emulators for development - Save on costs during development
Commit frequently - Each task should be a commit or series of commits
Document as you go - Add comments for complex logic
