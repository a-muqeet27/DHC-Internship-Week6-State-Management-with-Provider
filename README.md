# 📝 Task Management App

## 📌 Overview

It is a modern **to-do task management app** built with **Flutter** and **Dart**. It uses **Provider** for centralized state management, persists tasks locally with **SharedPreferences**, and includes smooth UI animations for a polished experience.

This project demonstrates how to build a responsive Flutter app with real-time UI updates, clean state handling, and local data persistence.

---

## ✨ Features

- ✅ Add new tasks
- ✅ Edit existing tasks
- ✅ Delete tasks
- ✅ Mark tasks as complete or incomplete
- ✅ Real-time UI updates using **Provider**
- ✅ Local persistence using **SharedPreferences**
- ✅ Animated summary card and task list transitions
- ✅ Clean Material 3 design
- ✅ Easy-to-use mobile-friendly interface

---

## 🛠️ Technologies Used

- Flutter
- Dart
- Provider
- SharedPreferences
- Material Design 3
- JSON serialization
- Animated UI transitions

---

## 📂 Project Structure

```text
lib/
├── main.dart
test/
└── widget_test.dart
```

---

## 📱 App Flow

1. Open the app to view your saved tasks.
2. Tap **Add Task** or use the floating action button to create a new task.
3. Toggle a task checkbox to update its completion status.
4. Tap the edit icon to update an existing task.
5. Tap the delete icon to remove a task.
6. All changes are saved locally and reflected instantly in the UI.

---

## 🧠 State Management

The app uses **Provider** with a `TaskProvider` (`ChangeNotifier`) to manage task data. This keeps the UI reactive and avoids handling state directly with `setState` inside widgets.

### Benefits

- Cleaner architecture
- Better separation of UI and logic
- Easier maintenance and scaling
- Automatic UI updates on state changes

---

## 🎨 UI/UX Highlights

- Gradient summary header
- Card-based task list
- Smooth fade and scale animations
- Strikethrough styling for completed tasks
- Minimal, modern layout

---

## 📌 Notes

- Tasks persist locally with `SharedPreferences`, so they remain available after app restart.
- The implementation is intentionally simple, while still demonstrating modern Flutter practices.
