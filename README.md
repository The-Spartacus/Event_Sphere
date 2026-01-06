# 🎯 EventSphere  
**Centralized Academic Event Discovery & Digital Certification Platform**

EventSphere is a full-stack mobile application designed to help **college students, institutions, and professional organizations** discover, manage, and certify academic and professional events such as seminars, workshops, internships, and training programs.

---

## 🚀 Features

### 👨‍🎓 Student
- Secure authentication
- Browse & search academic events
- Filter events by:
  - Category
  - Location (Online / Offline)
  - Price (Free / Paid)
  - Organization
- Event registration
- Personal **Digital Certificate Vault**
- Track registered and completed events

### 🏛️ Organization / Institution
- Organization profile management
- Create, edit, and delete events
- Specify:
  - Event category
  - Location & duration
  - Paid / Free events
  - Certificate availability
- Manage participant registrations
- Upload and issue digital certificates

### 🛡️ Admin
- Platform moderation
- Verify organizations
- Approve or reject events
- Maintain platform quality and authenticity

---

## 🧱 Tech Stack

### Frontend
- **Flutter**
- Provider (State Management)
- Material Design (Modern Clean UI)
- Android & iOS support

### Backend & Services
- **Firebase Authentication**
- **Firebase Firestore**
- Firebase Storage
- Firebase Cloud Functions (optional)

---

## 📂 Project Structure

```text
lib/
├── app/
│   ├── app.dart
│   ├── app_config.dart
│   └── routes.dart
│
├── core/
│   ├── constants/
│   │   ├── app_constants.dart
│   │   └── storage_keys.dart
│   ├── services/
│   │   ├── auth_service.dart
│   │   └── api_service.dart
│   └── theme/
│       ├── colors.dart
│       ├── text_styles.dart
│       └── app_theme.dart
│
├── features/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   └── role_selection_screen.dart
│   ├── events/
│   │   ├── data/
│   │   │   └── event_model.dart
│   │   ├── logic/
│   │   │   └── event_controller.dart
│   │   └── ui/
│   │       ├── event_list_screen.dart
│   │       ├── event_detail_screen.dart
│   │       └── event_filter_screen.dart
│   └── widgets/
│       ├── event_card.dart
│       ├── custom_button.dart
│       └── loading_indicator.dart
│
└── main.dart



git clone https://github.com/your-username/eventsphere.git
cd eventsphere


flutter pub get



---

If you want next:
- ✅ **GitHub badges**
- ✅ **Short README for project submission**
- ✅ **README with screenshots section**
- ✅ **Professional resume-ready description**

Just say the word, Sunny 🌞 is ready.
