# 🧠 TaskMe – Smart Task & Daily Planning App

TaskMe is a **Flutter + Firebase task management application** enhanced with **AI-powered daily planning**.  
It helps users manage tasks, track productivity, and automatically generate a **fully time-planned day** based on task deadlines.


---

## ✨ Features

### ✅ Task Management
- Create, edit, and delete tasks
- Task statuses:
  - **PENDING**
  - **DONE**
  - **MISSED**
- Optional deadlines (date & time)
- Sorting and filtering:
  - By status
  - By deadline (oldest / newest)

---

### 📊 Productivity Overview
- User profile dashboard with:
  - All-time statistics
  - Last 7 days statistics
  - Last month statistics
- Visual overview of:
  - Completed tasks
  - Missed tasks
  - Pending tasks

---

### 🤖 AI Daily Planner (Core Feature)
- Generates a **fully scheduled daily plan**
- Uses **only tasks that have deadlines TODAY**
- Each task includes:
  - Exact start & end time
  - Deadline-respecting scheduling
- Automatically adds:
  - Breaks
  - Realistic task spacing
- Provides a **Tips** section for handling missed tasks

> AI logic runs securely in **Firebase Cloud Functions**, keeping API keys safe.

---

### 💾 Saved Daily Plans
- Generate and save daily plans
- View all previously generated plans
- Open a plan to see full details
- Delete saved plans
- Each saved plan contains:
  - Title (based on date)
  - Full schedule
  - Tips section

---

### 🔐 Authentication
- Firebase Authentication
- User-specific data isolation
- Sign up / sign in / sign out functionality

---

### 🎨 UI & UX
- Clean, minimal design
- Custom header & footer navigation
- Centralized theme configuration
- Consistent card-based UI
- Responsive layouts

---

## 🛠️ Tech Stack

### Frontend
- **Flutter**
- Material Design (Material 3)
- Custom theme system

### Backend & Cloud
- **Firebase**
  - Firestore
  - Authentication
  - Cloud Functions
- **OpenAI API** (via Firebase Functions)

### Architecture
- Service-based architecture
- Clear separation of:
  - Screens
  - Services
  - Models
  - Theme

---

## 🔐 Security
- OpenAI API key stored using **Firebase Secrets**
- AI calls executed only in Cloud Functions
- No sensitive credentials exposed to the client

---

## 🧩 Project Structure

```text
lib/
 ├─ src/
 │   ├─ screens/        # App screens
 │   ├─ services/       # Firebase & AI services
 │   ├─ models/         # Data models
 │   ├─ components/     # Header, footer, reusable UI
 │   └─ theme/          # Theme & colors
functions/
 └─ src/
    └─ index.ts         # Firebase Cloud Function (AI planner)
```

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![OpenAI](https://img.shields.io/badge/OpenAI-412991?style=for-the-badge&logo=openai&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Material 3](https://img.shields.io/badge/Material%203-757575?style=for-the-badge&logo=material-design&logoColor=white)

