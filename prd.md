Product Requirements Document: messageAI (MVP)
1. Executive Summary
Product Name: messageAI
Target Platform: iOS (Swift + SwiftUI)
Primary Goal: Build a production-ready messaging infrastructure that demonstrates reliable, real-time message delivery across one-on-one and group conversations.
Success Criteria: The MVP is complete when the messaging infrastructure reliably handles all core scenarios including offline message queuing, optimistic updates, and graceful degradation under poor network conditions.

2. Product Objectives
MVP Goals

Prove messaging infrastructure reliability over feature breadth
Demonstrate real-time message sync across multiple devices
Handle edge cases (offline, poor network, app termination) gracefully
Create foundation for future feature expansion


3. User Personas
Primary User: Mobile-first communicator who expects instant message delivery and reliable chat history across all network conditions.
Use Cases:

Send quick messages to friends/colleagues
Participate in group conversations
Access message history offline
Know when messages are read


4. Core Features & Requirements
4.1 User Authentication
Priority: P0 (MVP Blocker)
Requirements:

Email/password authentication via Firebase Auth
User profile creation with display name, unique username, and profile picture
Persistent login state across app restarts
Account management (logout functionality)
Username uniqueness validation

Acceptance Criteria:

 Users can create accounts with email/password
 Users can log in/out
 Profile includes editable display name, unique username, and profile picture
 Login state persists across app restarts
 Username must be unique across all users
 Username validation prevents duplicates


4.2 User Discovery
Priority: P0 (MVP Blocker)
Requirements:

Search for users by username
Add users to contacts list
View contact profiles (display name, username, profile picture only)
Profiles only visible to users who have added them as contacts

Acceptance Criteria:

 Users can search for other users by username
 Search returns matching usernames
 Users can add contacts from search results
 Contact profiles show display name, username, and profile picture
 Non-contacts cannot view full profile details


4.3 One-on-One Chat
Priority: P0 (MVP Blocker)
Requirements:

Start conversation with any contact
Send/receive text messages in real-time
Message timestamps (display in user's local timezone)
Conversation list showing recent chats
Unread message indicators

Acceptance Criteria:

 Users can initiate chat with contacts
 Messages appear in real-time for both parties (< 2s latency)
 Conversation list shows last message and timestamp
 Unread count displays on conversation list items
 Chat history loads on conversation open


4.4 Group Chat
Priority: P0 (MVP Blocker)
Requirements:

Create group with 3+ participants
Group name and optional group avatar
All messages visible to all group members
Message attribution (who sent what)
Any member can add participants to existing groups

Acceptance Criteria:

 Users can create groups with 3+ members
 Group messages sync in real-time to all members
 Each message clearly shows sender identity
 Any group member can add new participants
 Group name editable by members


4.5 Real-Time Message Delivery
Priority: P0 (MVP Blocker)
Requirements:

WebSocket/Firestore realtime listeners for instant delivery
Message delivery states: sending → sent → delivered → read
Optimistic UI updates (message appears locally before server confirmation)
Offline message queuing (messages send when connectivity returns)
Handle concurrent messages from multiple users
Rate limiting to prevent spam (configured server-side)

Acceptance Criteria:

 Messages appear instantly for sender (optimistic update)
 Online recipients receive messages within 2 seconds
 Messages sent offline queue and send automatically when online
 Delivery status updates visible to sender
 20+ rapid-fire messages deliver without loss or reordering
 Rate limiting prevents spam abuse


4.6 Message Persistence
Priority: P0 (MVP Blocker)
Requirements:

Local database (SwiftData) stores all messages
Messages survive app restarts and force-quits
Messages retained forever (no automatic deletion)
Sync strategy: local-first with cloud backup
Pagination for long chat histories

Acceptance Criteria:

 All messages accessible after app restart
 Chat history persists after force-quit
 Messages available offline
 Long conversations load efficiently (paginated)
 Local data syncs with server on reconnection
 Messages never auto-delete


4.7 Presence & Typing Indicators
Priority: P0 (MVP Blocker)
Requirements:

Online/offline status indicators
Last seen timestamp for offline users
Typing indicators (show when user is composing)
Presence updates in real-time

Acceptance Criteria:

 User status (online/offline) visible in chat header
 Status updates within 10 seconds of state change
 Typing indicator appears when user types
 Typing indicator disappears after 3s of inactivity
 Last seen displays for offline users


4.8 Read Receipts
Priority: P0 (MVP Blocker)
Requirements:

Track when messages are read by recipients
Visual indicators for read status (checkmarks, avatars)
Read receipts for both 1-on-1 and group chats
Group chats show partial read states

Acceptance Criteria:

 Sender sees when message is read
 1-on-1: Double checkmark or visual indicator on read
 Groups: Show which members have read each message
 Read receipts update in real-time


4.9 Media Sharing
Priority: P0 (MVP Blocker)
Requirements:

Send images from photo library or camera
Image thumbnails in chat view
Full-size image viewer
Profile picture upload
Image storage via Firebase Storage

Acceptance Criteria:

 Users can select and send images
 Images appear as thumbnails inline in chat
 Tap to view full-size image
 Profile pictures upload and display
 Images persist locally and sync to cloud


4.10 Push Notifications
Priority: P0 (MVP Blocker)
Requirements:

Firebase Cloud Messaging integration
Foreground notifications working at minimum
Notification shows sender name and message preview
Tap notification opens relevant chat

Acceptance Criteria:

 Foreground notifications display for new messages
 Notification includes sender and message preview
 Tapping notification navigates to chat
 (Stretch) Background and killed-state notifications work


4.11 Network Resilience
Priority: P0 (MVP Blocker)
Requirements:

Graceful degradation under poor network (3G, packet loss)
Automatic reconnection after connectivity loss
Clear UI feedback for connectivity issues
Retry logic for failed operations
Message queue persists across app restarts

Acceptance Criteria:

 Messages queue offline and send when online
 App reconnects automatically after airplane mode
 Network errors shown to user with retry option
 No message loss during force-quit or crash
 App functions in 3G/throttled conditions


5. Technical Architecture
5.1 Technology Stack
Mobile (iOS):

Swift 5.9+
SwiftUI for UI layer
SwiftData for local persistence
Combine for reactive programming
URLSession for REST API calls
Firebase iOS SDK

Backend:

Firebase Firestore (real-time database)
Firebase Auth (authentication)
Firebase Cloud Functions (serverless logic, rate limiting)
Firebase Cloud Messaging (push notifications)
Firebase Storage (image/media storage)

Deployment:

TestFlight for beta distribution
Xcode Cloud or manual builds


5.2 Data Models
User
- id: String (UID)
- displayName: String
- username: String (unique, indexed)
- email: String
- profilePictureURL: String?
- isOnline: Bool
- lastSeen: Timestamp
- fcmToken: String?
- contacts: [String] (user IDs of added contacts)
- createdAt: Timestamp
```

**Conversation**
```
- id: String
- type: Enum (oneOnOne, group)
- participants: [String] (user IDs)
- groupName: String? (for groups)
- groupAvatarURL: String?
- lastMessage: String
- lastMessageTimestamp: Timestamp
- createdAt: Timestamp
- createdBy: String (user ID)
```

**Message**
```
- id: String
- conversationId: String
- senderId: String
- content: String
- type: Enum (text, image)
- mediaURL: String? (for images)
- timestamp: Timestamp
- deliveryStatus: Enum (sending, sent, delivered, read)
- readBy: [String] (user IDs for group chats)
- localId: String? (for optimistic updates)
```

**TypingIndicator**
```
- conversationId: String
- userId: String
- isTyping: Bool
- timestamp: Timestamp
```

**RateLimit** (Firestore collection for tracking)
```
- userId: String
- messageCount: Int
- windowStart: Timestamp
- lastMessageTime: Timestamp

5.3 Key Technical Decisions
Local-First Architecture:

SwiftData as source of truth for UI
Background sync with Firestore
Optimistic updates write to SwiftData immediately

Real-Time Sync:

Firestore snapshot listeners for active conversations
WebSocket-like behavior via Firestore's realtime capabilities
Disconnect handling and automatic reconnection

Message Queue:

Failed/offline messages stored in SwiftData with retry flag
Background service monitors connectivity and flushes queue
Persist queue across app restarts

Image Handling:

Compress images before upload
Generate thumbnails for chat view
Cache images locally (NSCache + disk)
Upload to Firebase Storage, store URL in message

Rate Limiting:

Firebase Cloud Functions enforce rate limits
Example: 100 messages per minute per user
Return error to client if limit exceeded
Client displays appropriate error message

Username System:

Usernames stored lowercase for case-insensitive search
Firestore security rules enforce uniqueness
Index on username field for fast search
Username change requires re-validation


6. User Flows
6.1 First-Time User

Launch app → shown login/signup screen
Create account with email/password
Choose unique username
Set display name and optional profile picture
Land on empty conversation list
Tap "New Chat" → Search for users by username
Add contacts and start conversations

6.2 Finding and Adding Contacts

Tap "New Chat" or "Add Contact"
Enter username in search field
View search results
Tap user to view limited profile (if not a contact)
Add to contacts
Start conversation or return to contact list

6.3 Sending First Message

Select contact or create group
Type message in input field
Tap send
Message appears immediately in chat (optimistic)
Delivery status updates: sent → delivered → read

6.4 Receiving Message (Online)

User is in conversation list
New message arrives via Firestore listener
Notification appears (if app in foreground)
Conversation list updates with new message preview
If conversation is open, message appears in chat view

6.5 Receiving Message (Offline)

User goes offline (airplane mode)
Messages accumulate in Firestore
User comes back online
App reconnects, Firestore listeners trigger
New messages sync to local SwiftData
Conversation list and chat views update

6.6 App Force-Quit Recovery

User sends message
App crashes or is force-quit
User reopens app
SwiftData loads local messages
Unsent messages detected in queue
Firebase connection re-established
Queued messages sent automatically

6.7 Creating Group Chat

Tap "New Group"
Select 2+ contacts from list
Set group name and optional avatar
Tap "Create"
Group chat opens, all members notified
Any member can add more participants later


7. Testing Requirements
7.1 MVP Testing Scenarios (Hard Gate)
Test 1: Real-Time Two-Device Chat

Setup: Two iOS devices, both online
Action: Send messages back and forth
Expected: Messages appear within 2 seconds, correct order

Test 2: Offline/Online Transition

Setup: Device A online, Device B offline
Action: Device A sends 5 messages, Device B goes online
Expected: All 5 messages appear on Device B immediately

Test 3: Background Message Delivery

Setup: Device A in background, Device B sends message
Action: Device B sends message
Expected: Device A receives notification, message appears when opened

Test 4: Persistence After Force-Quit

Setup: Active conversation with 20+ messages
Action: Force-quit app, reopen
Expected: All messages visible, unsent messages in queue

Test 5: Poor Network Conditions

Setup: Throttle network to 3G or use Network Link Conditioner
Action: Send 10 messages rapidly
Expected: All messages queue, send eventually, no loss

Test 6: Rapid-Fire Messages

Setup: Two devices online
Action: Send 20+ messages in quick succession
Expected: All messages deliver in correct order, no duplicates

Test 7: Group Chat (3+ Users)

Setup: Group with 3 participants
Action: All participants send messages
Expected: All messages visible to all participants, correct attribution

Test 8: Username Search and Contact Discovery

Setup: Multiple registered users
Action: Search for users by username, add as contacts
Expected: Search returns correct results, contacts added successfully

Test 9: Rate Limiting

Setup: Single device online
Action: Attempt to send 150 messages in 60 seconds
Expected: After ~100 messages, rate limit error displayed, messages queue until limit resets


7.2 Quality Assurance Metrics
Performance:

Message send latency: < 500ms (local optimistic update)
Message delivery latency: < 2s (to online recipient)
App launch time: < 3s to conversation list
Chat load time: < 1s for 100-message conversation
Username search: < 1s for results

Reliability:

Message delivery success rate: 99.9%
Zero message loss under any condition
Automatic recovery from all error states
Username uniqueness: 100% enforced

Network Resilience:

Support 3G speeds (minimum)
Handle 50% packet loss
Recover from 60+ second disconnections


8. Deployment Plan
8.1 MVP Deployment Requirements
Minimum Viable Deployment:

Running on local iOS simulator with deployed Firebase backend
TestFlight distribution (preferred but not required for MVP checkpoint)

Firebase Setup:

Production Firebase project configured
Firestore database deployed with security rules
Firebase Auth enabled
Cloud Storage configured
FCM certificates/keys configured
Cloud Functions deployed (rate limiting)

iOS Build:

Xcode project builds without errors
No critical warnings
Provisioning profiles configured
App runs on physical device (if TestFlight)


8.2 Post-MVP Deployment
Beta Testing:

TestFlight distribution to 10-20 beta testers
Collect feedback on reliability and UX
Monitor Firebase Analytics for crash reports

Production Readiness:

App Store compliance review
Privacy policy and terms of service
App Store assets (screenshots, description)


9. Resolved Questions
✅ App Name: messageAI
✅ User Discovery: Username search
✅ Group Admin Controls: Anyone can add members to groups
✅ Message Retention: Messages kept forever
✅ Rate Limiting: Yes, implemented server-side
✅ Profile Privacy: Profiles only visible to contacts
✅ Notification Settings: Not included in MVP

10. Success Metrics
MVP Checkpoint Success:

All 9 testing scenarios pass
Zero message loss in any scenario
App runs stably for 1-hour test session
Positive feedback from 3+ technical reviewers

Post-Launch Metrics:

Message delivery success rate > 99%
App crash rate < 1%
User retention: 40%+ day-7 retention
Username search success rate > 95%


11. Timeline & Milestones
Phase 0: Setup (Week 1)

Firebase project configuration
Xcode project setup with SwiftUI + SwiftData
Firebase SDK integration
Basic authentication screen with username

Phase 1: Core Messaging (Weeks 2-3)

Username search and contact management
One-on-one chat UI
Real-time message delivery
SwiftData persistence
Optimistic UI updates

Phase 2: Resilience (Week 4)

Offline message queuing
Network error handling
Presence indicators
Read receipts
Rate limiting implementation

Phase 3: Group Chat & Media (Week 5)

Group chat functionality
Image sending/receiving
Push notifications (foreground)

Phase 4: Testing & Polish (Week 6)

Execute all 9 MVP test scenarios
Bug fixes and edge case handling
TestFlight deployment
MVP checkpoint review


Document Version: 1.1
Last Updated: October 20, 2025

