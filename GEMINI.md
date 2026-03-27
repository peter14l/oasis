\# GEMINI.md



\## 🧠 Project Overview



This is a Flutter application using a layered architecture.



Structure is organized by responsibility:

\- UI → screens/, widgets/

\- State → providers/

\- Logic → services/

\- Data → models/

\- Routing → routes/



Do NOT assume feature-based modular structure.



\---



\## 📁 Directory Responsibilities



\- main.dart → App entry point

\- config/ → App configuration and setup

\- exceptions/ → Custom error handling

\- models/ → Data models (pure Dart classes)

\- providers/ → State management (business logic + state)

\- services/ → API calls, backend logic, external integrations

\- routes/ → Navigation and route definitions

\- screens/ → Full UI screens

\- widgets/ → Reusable UI components

\- themes/ → Styling and theme data

\- utils/ → Helper functions



\---



\## 🚫 Strict Ignore Rules



Gemini MUST NEVER analyze:



\- build/

\- .dart\_tool/

\- .git/

\- ios/

\- android/

\- macos/

\- windows/

\- linux/

\- web/

\- generated files (\*.g.dart, \*.freezed.dart)



ONLY analyze:

👉 lib/



\---



\## ⚠️ Critical Behavior Rules



1\. Do NOT scan the entire project

2\. Only use files explicitly provided

3\. If context is missing → ASK for files

4\. Never assume architecture beyond given structure



\---



\## 🎯 Code Understanding Strategy



When analyzing:



Step 1 → Identify layer:

\- UI (screens/widgets)

\- State (providers)

\- Logic (services)

\- Data (models)



Step 2 → Trace flow:

UI → Provider → Service → Model



Step 3 → Then answer



\---



\## 🛠️ Task Rules



\### Bug Fixing

\- Find exact issue

\- Suggest minimal fix

\- Do NOT rewrite unrelated code



\### Feature Development

\- Use:

&#x20; - providers for state

&#x20; - services for logic

\- Do NOT put logic inside UI



\### Refactoring

\- Keep folder structure unchanged

\- Avoid large rewrites



\---



\## ⚡ Performance Constraints



\- Max 3 files per analysis

\- Prefer summaries before deep dives

\- Keep responses under 300 words unless asked



\---



\## 🧪 Prompt Protocol (VERY IMPORTANT)



Always follow:



1\. Ask for files (if not provided)

2\. Summarize them

3\. Then perform task



\---



\## 🧱 Example Good Prompt



"Analyze state flow between:

\- screens/home\_screen.dart

\- providers/home\_provider.dart

\- services/api\_service.dart



Explain data flow and suggest improvements."



\---



\## ❌ Bad Prompt



"Explain my entire app"

"Fix everything"

