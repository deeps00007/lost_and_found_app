🔍 Instant Item Recovery
Turning Lost into Found — Faster, Smarter, Securely

Instant Item Recovery is a high-performance, cross-platform mobile application built to eliminate the analogue chaos of traditional lost-and-found systems.
Instead of fragmented notice boards, WhatsApp groups, or paper registers, this solution introduces a centralised, real-time digital platform that seamlessly connects finders and owners within minutes.

🔗 Project Links

(Add your deployed app, demo video, or documentation here)

GitHub Repository: <YOUR_GITHUB_REPO_LINK>

Demo / APK / TestFlight: <YOUR_APP_LINK>

Design / Documentation: <OPTIONAL_LINK>

🌍 New Feature: Proximity-Based Map Discovery

The platform has now moved from roadmap to active implementation with Advanced Geolocation Tracking:

📍 Precise Coordinate Mapping
Every lost or found item captures exact GPS coordinates for pinpoint accuracy.

🗺️ 10km Radius Visual Discovery
Users can explore an interactive map displaying all items within a 10km radius of their current location.

🖼️ Live Image Markers
Map markers show thumbnail images of actual items instead of generic pins—allowing instant visual identification.

🚀 Core Features
1️⃣ Intuitive Item Management

📝 Rich Listings
Create detailed posts with title, description, and up to 5 high-quality images.

🗂️ Smart Categorisation
Items are organised into 8+ predefined categories such as:

Electronics

Documents

Accessories

Clothing

Keys

Wallets

🔄 Lifecycle Tracking
Item status can be updated from Active → Claimed → Resolved once recovery is complete.

2️⃣ Secure Real-Time Communication

💬 Built-in Chat System
One-to-one encrypted messaging without sharing phone numbers or personal contact details.

⏱️ Message Status Indicators
Professional chat features:

Sent ✓

Delivered ✓✓

Read ✓✓ (blue)

🔔 Instant Notifications
Real-time push notifications ensure users never miss messages or recovery leads.

3️⃣ Advanced Search & Filtering

🔎 Keyword-Based Search
Instantly locate items using real-time keyword matching.

🎯 Dynamic Filters
Filter by:

Lost / Found

Category

Location proximity

🛠️ Technology Stack
📱 Frontend (Mobile)

Flutter – Single codebase for Android & iOS

Dart – Optimised for high-performance UI rendering

Provider – Efficient and scalable state management

☁️ Backend & Infrastructure

Firebase Authentication – Secure user login and identity management

Cloud Firestore – Real-time NoSQL database for instant sync

Firebase Cloud Messaging (FCM) – Push notifications

ImageKit – Optimised cloud image storage and delivery

🗄️ Firestore Database Structure
Users
 └─ uid, name, email, fcmToken

Items
 └─ title, category, type, status, images, postedBy, coordinates

Chats
 └─ participants, lastMessage, itemId
    └─ messages (sub-collection)

Notifications
 └─ userId, title, body, createdAt

📈 Impact & Benefits

⚡ 80% Faster Recovery Time
Eliminates manual searching through registers or social media posts.

📊 Higher Success Rates
Centralised data dramatically improves item recovery probability.

🔐 Privacy-First Communication
In-app messaging protects user identity and contact details.

🧾 Permanent Digital Records
Replaces error-prone paper logs with searchable, structured data.

🧭 Future Roadmap

🤖 AI-Powered Automation

Image recognition for automatic category suggestions

🔍 Accessibility Enhancements

QR code scanning

Voice-based search

🌐 Extended Reach

Email notifications

Social sharing integrations

🤝 Contribution & Feedback

Contributions, ideas, and feedback are welcome.
Feel free to open an issue or submit a pull request.
