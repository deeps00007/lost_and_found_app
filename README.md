# lost_and_found_app
- **APK :** <[Google Drive Downlaod](https://drive.google.com/file/d/1rOyZoW06bw5SfMzTuaKNbR6H3g4Z1rFw/view?usp=sharing)>

---

# Instant Item Recovery: Turning ‘Lost’ into ‘Found’

**Instant Item Recovery** is a high-performance, cross-platform mobile solution designed to solve the "analogue chaos" of traditional lost and found systems. By replacing fragmented notice boards and manual ledgers with a **centralised digital platform**, it provides a seamless way for finders and owners to connect in real-time.

---

## 📍 New Feature: Proximity-Based Map Discovery

Moving from our initial roadmap into active implementation, the platform now features **Advanced Geolocation Tracking**.

*   **Precise Coordinate Mapping:** Every item reported captures exact GPS coordinates to provide pinpoint accuracy for recovery.
*   **10km Visual Discovery:** Users can view an interactive map that highlights all lost and found items within a **10km radius** of their current location.
*   **Live Image Markers:** Instead of simple pins, the map uses **thumbnail images** of the actual items, allowing for immediate visual identification directly from the map interface.

---

## 🚀 Core Functionalities

### **1. Intuitive Item Management**
*   **Rich Postings:** Users can create detailed posts including a comprehensive title, description, and up to **5 high-quality images** for clear identification.
*   **Smart Categorisation:** Items are organised into **8+ predefined categories** (e.g., Electronics, Documents, Accessories, Clothing, Keys, Wallet) to ensure superior searchability.
*   **Lifecycle Tracking:** Owners can manage the status of their posts, updating them from **‘Active’ to ‘Claimed’ or ‘Resolved’** once the item is recovered.

### **2. Secure Real-Time Communication**
*   **Integrated Chat System:** A secure, one-on-one messaging system that eliminates the need to share personal contact details like phone numbers.
*   **Message Status Indicators:** Professional-grade chat features including **timestamps** and visual status icons: sent (✓), delivered (✓✓), and **read (blue ✓✓)**.
*   **Instant Alerts:** Real-time **push notifications** ensure users never miss a message or a potential lead.

### **3. Advanced Search & Filtering**
*   **Keyword Discovery:** Utilise a real-time, keyword-based search to find specific items instantly.
*   **Dynamic Filtering:** Filter results by type (Lost vs. Found) or specific category to cut through the noise.

---

## 🛠️ Modern Technology Stack

The application is built on a **robust client-server architecture** designed for scale and responsiveness.

### **Frontend (Mobile)**
*   **Flutter:** Used to build a seamless, native experience for both **Android and iOS** from a single codebase.
*   **Dart:** The primary language, highly optimised for fast UI rendering.
*   **Provider:** Implemented for efficient **state management** across the entire application.

### **Backend & Infrastructure**
*   **Firebase Authentication:** Provides secure user management and token-based access.
*   **Cloud Firestore:** A real-time **NoSQL database** used to synchronise users, items, and chats instantly.
*   **Firebase Cloud Messaging (FCM):** Powers the reliable delivery of push notifications.
*   **ImageKit:** A specialised cloud service for **optimised image storage**, delivery, and hosting.

---

## 📂 Firestore Database Blueprint

The data is structured into four primary collections to ensure integrity and real-time updates:

*   **Users:** `uid`, `name`, `email`, `fcmToken`.
*   **Items:** `title`, `category`, `type`, `status`, `images`, `postedBy`, `coordinates`.
*   **Chats:** `participants`, `lastMessage`, `itemId`, and a `messages` sub-collection.
*   **Notifications:** `userId`, `title`, `body`, `createdAt`.

---

## 📈 Tangible Impact
*   **80% Time Savings:** Radically reduces the time spent searching through manual records or disparate social media groups.
*   **Higher Recovery Rates:** Centralising the data significantly increases the chances of successful reunions.
*   **Enhanced Security:** Direct in-app communication protects user privacy and data.
*   **Digital Clarity:** Replaces error-prone spreadsheets and paper ledgers with permanent, searchable digital records.

---

## 🗺️ Future Roadmap
*   **AI & Automation:** AI-powered image recognition to automatically suggest categories based on uploaded photos.
*   **Greater Accessibility:** QR code integration for quick item scanning and voice search functionality.
*   **Enhanced Connectivity:** Email notifications to supplement push alerts and social sharing to extend the reach of posts.

**Instant Item Recovery** serves as a versatile, deployable solution that bridges the gap between lost items and their owners, creating more connected and helpful communities.
