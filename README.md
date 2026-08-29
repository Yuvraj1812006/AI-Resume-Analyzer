# 🤖 AI Resume Analyzer

An AI-powered resume analysis application built using **Flutter, Node.js, Express.js, and Gemini AI**. The application allows users to upload a PDF resume, extracts its content, evaluates resume quality, and provides AI-generated insights and improvement suggestions.

## 🚀 Features

* 📄 Upload PDF resume
* 🔍 Extract text from PDF
* 🤖 AI-powered resume analysis using Gemini
* 📊 Placement readiness score out of 100
* 💻 Technical skills evaluation
* 📁 Project evaluation
* 🎓 Education evaluation
* 💼 Experience & achievements evaluation
* 📋 ATS and resume quality evaluation
* 🗣️ Communication & presentation evaluation
* ✅ Resume strengths
* ⚠️ Missing / weak skills
* 💡 Personalized improvement suggestions
* 💼 Suitable entry-level job roles
* 📑 Generate and share analysis as PDF
* 🌐 Node.js backend deployed on Render

## 🛠️ Tech Stack

### Frontend

* Flutter
* Dart
* Syncfusion Flutter PDF
* File Picker
* HTTP

### Backend

* Node.js
* Express.js
* Google Gemini AI
* CORS
* dotenv

### Deployment

* Backend: Render
* Source Code: GitHub

## 🧠 How It Works

```text
User
  ↓
Upload Resume PDF
  ↓
Flutter Application
  ↓
Extract Resume Text
  ↓
Calculate Resume Score
  ↓
Send Resume Text to Backend
  ↓
Node.js + Express.js
  ↓
Gemini AI
  ↓
Generate Resume Analysis
  ↓
Flutter Results Dashboard
  ↓
Download Analysis PDF
```

## 📊 Resume Scoring

The application calculates a placement readiness score out of 100:

| Category                     | Maximum Score |
| ---------------------------- | ------------: |
| Technical Skills             |            20 |
| Projects                     |            20 |
| Education                    |            15 |
| Experience & Achievements    |            15 |
| ATS & Resume Quality         |            15 |
| Communication & Presentation |            15 |
| **Total**                    |       **100** |

## 📋 AI Analysis

The AI provides:

* Professional Summary
* Skills Found
* Strengths
* Missing / Weak Skills
* Project Analysis
* Education Summary
* Suitable Job Roles
* Improvement Suggestions

The AI is instructed to use only information actually present in the uploaded resume and avoid inventing qualifications or experience.

## ⚙️ Backend Setup

Clone the repository:

```bash
git clone https://github.com/Yuvraj1812006/AI-Resume-Analyzer.git
```

Navigate to the backend directory:

```bash
cd backend
```

Install dependencies:

```bash
npm install
```

Create a `.env` file:

```env
GEMINI_API_KEY=your_gemini_api_key
```

Start the backend:

```bash
node server.js
```

## 📱 Flutter Setup

Install Flutter and make sure it is configured correctly.

Get dependencies:

```bash
flutter pub get
```

Run the application:

```bash
flutter run
```

## 🔐 Security

The Gemini API key is stored as an environment variable and is **not hard-coded into the Flutter application**.

The `.env` file should never be committed to GitHub.

## 🔮 Future Improvements

* Job description matching
* Resume keyword optimization
* User authentication
* Resume history
* More advanced ATS analysis
* Improved analytics dashboard

## 👨‍💻 Developer

**Yuvraj Singh**

B.Tech – Computer Science & Information Technology

## 📄 License

This project is created for educational and portfolio purposes.

## 📸 Screenshots

### 1. Home Screen

![Home Screen](lib/screenshots/Screenshot%202026-08-29%20142954.png)

### 2. Resume Upload

![Resume Upload](lib/screenshots/Screenshot%202026-08-29%20143105.png)

### 3. Placement Readiness Score

![Placement Score](lib/screenshots/Screenshot%202026-08-29%20143144.png)

### 4. Score Breakdown

![Score Breakdown](lib/screenshots/Screenshot%202026-08-29%20143221.png)

### 5. AI Resume Analysis

![AI Analysis](lib/screenshots/Screenshot%202026-08-29%20143250.png)

### 6. Analysis Report

![Analysis Report](lib/screenshots/Screenshot%202026-08-29%20143532.png)

