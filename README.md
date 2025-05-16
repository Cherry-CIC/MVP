# CherryMVP
 
### Project Structure

```
assets/
│   ├── images/       # Stores image assets
│   └── fonts/        # Custom fonts
lib/
├── core/             # Core functionalities shared across the app
│   ├── config/       # App constants
│   │   ├── app_colors.dart    # Colors used in the app
│   │   ├── app_strings.dart   # App strings (for localization readiness)
│   │   ├── config.dart        # Simplified imports for config files
│   ├── models/                # General models
│   ├── services/              # Services (external dependencies like network)
│   ├── utils/                 # Helper utilities
│   ├── reusablewidgets/       # Shared reusable widgets
│   └── router/                # Handles navigation
├── features/                  # Main features
│   ├── login/                 
│   │   ├── models/
│   │   │   ├── login_model.dart  
│   │   ├── repository/
│   │   │   ├── login_repository.dart  
│   │   ├── viewmodel/
│   │   │   ├── login_viewmodel.dart   
│   │   ├── ui/
│   │   │   ├── loginpage.dart   
│   │   └── widgets/                # Sub-widgets used in login
│   ├── register/              
│   ├── home/                 
│   ├── dashboard/          
│   ├── profile/               
└── main.dart                  # Entry point
```
### Key Points:
- **MVVM Architecture**: The project uses the **MVVM approach** for separation of concerns.
- **Provider**: The project uses **Provider** for state management and dependency injection.
- **Feature Consistency**: Other features should follow the same approach as the **Login feature**, to ensure consistency.
- **Welcome Page/LoginForm**: The **Pages** provide good example of how to navigate between screens and use other dependencies/resources within the app.
---

## Setup and How to Contribute
### Prerequisites

Make sure you have the following installed:

- Flutter SDK (latest stable version)
- Android Studio (Recommended) / VS Code
- An emulator or a real device

### Step 1: Pick Up an Issue
- Before you start working on a feature or bug fix, check the issues tab and pick one that you’d like to work on.

### Step 1: Clone the Repository
```shell
git clone https://github.com/CherryCIC/MVP
cd CherryMVP
```

### Step 2: Create a Feature Branch from main
```shell
git checkout -b feature-new-feature
```

### Step 3: Install Dependencies
- Create a .env file in the root directory and update it with necessary credentials 
```shell
flutter clean (optional)
flutter pub get
```

### Step 4: run the project
```shell
flutter run
```

### Step 5: Submit a Pull Request
- Once you’re done with your changes, submit a pull request from your feature branch to the main branch of the CherryMVP repository

### Step 6: Follow the PR Guidelines
- Add screenshots or images of any UI changes.
- Provide a clear description of the changes made.
- Ensure that the code follows the project's coding standards
- Mention the issue number your PR addresses.
Use the following format in your pull request description:
```shell
Fixes: #<issue_number>
```
This helps us track which issue the PR is resolving. Here's an example of a good PR description:
```shell
Fixes: #97

### Description of the Work Done:
- Created the login UI
- Integrated basic validation

### Screenshot (if UI was created or updated):
[Attach screenshot here]
```

### Understanding the Project Architecture
To better understand the architecture of this project, please take a look at:
- https://jimohyusuph.hashnode.dev/designing-the-mobile-architecture-for-cherry-flutter-app-my-thought-process
it may also be helpful to read the official Flutter documentation using the links below: 
- UI: https://docs.flutter.dev/ui/layout
- Flutter App Architecture Guide: https://docs.flutter.dev/app-architecture/concepts
- Compass App case study:https://docs.flutter.dev/app-architecture/case-study
- Navigation: https://docs.flutter.dev/cookbook/navigation/navigation-basics
- State Management: https://docs.flutter.dev/data-and-backend/state-mgmt/simple

### Few House Keeping Notes
- Please avoid using relative imports for items from the core folder. It's best to use the package-based import structure. For example:
```dart 
import 'package:cherry_mvp/core/utils/utils.dart'; 
```

- Avoid using relative imports, such as:
```dart 
import '../../core/utils/result.dart';
```

- Avoid hardcoding strings, images, and colors directly in the widgets. They should be referenced from app_colors, app_images, and app_strings.
```dart 
import 'package:cherry_mvp/core/config/config.dart';
```
