# Landing Page & Navigation Architecture Update

**Status**: Design Specification  
**Created**: January 16, 2026

---

## Overview

This document specifies the architectural changes needed to make the Landing Page with Slideshow the primary entry point, with all other pages and navigation hidden until user login.

---

## Part A: Current State vs. Desired State

### A.1 Current Routing (App.tsx)

```tsx
// Current: All routes directly accessible
<Routes>
  <Route path="/" element={<LandingPage />} />
  <Route path="/dashboard" element={<ObjectDashboard ... />} />
  <Route path="/forms/:entityName" element={<FormWizardPage ... />} />
  <Route path="/admin/form-configurations" element={<FormConfigListPage />} />
  {/* ... more routes ... */}
</Routes>

// Navigation always shows
<Navigation objectTypes={objectTypes} />
```

### A.2 Desired State

```
PUBLIC (Always Visible):
├── Landing Page with Slideshow
├── Sign Up / Login Links
└── Error Messages

PROTECTED (Only After Login):
├── Navigation (hidden until login)
├── Dashboard
├── Forms / Entity Management
├── Admin Panel
└── All Other Pages
```

---

## Part B: Implementation Strategy

### B.1 Architecture Changes

```tsx
// App.tsx (UPDATED)
import { useAutoLogin } from './hooks/useAutoLogin';
import ProtectedRoute from './components/ProtectedRoute';

function App() {
  // Auto-check session on app load
  const { isCheckingSession, isLoggedIn, user } = useAutoLogin();

  // Show loading while checking session
  if (isCheckingSession) {
    return <LoadingScreen />;
  }

  return (
    <Router>
      <div className="min-h-screen bg-gray-100">
        {/* Navigation only shows if logged in */}
        {isLoggedIn && <Navigation objectTypes={objectTypes} />}

        {/* Main content with conditional padding based on nav visibility */}
        <div className={isLoggedIn ? "pt-16 p-8" : ""}>
          <div className={isLoggedIn ? "max-w-7xl mx-auto space-y-12" : ""}>
            <Routes>
              {/* PUBLIC ROUTES (Always accessible) */}
              <Route path="/" element={<LandingPage onLoginSuccess={() => window.location.reload()} />} />
              <Route path="/auth/register" element={<RegisterPage onRegisterSuccess={() => window.location.reload()} />} />
              <Route path="/auth/login" element={<LoginPage onLoginSuccess={() => window.location.reload()} />} />

              {/* PROTECTED ROUTES (Only after login) */}
              <Route path="/dashboard" element={
                <ProtectedRoute isLoggedIn={isLoggedIn}>
                  <ObjectDashboard objectTypes={objectTypes} />
                </ProtectedRoute>
              } />
              <Route path="/forms" element={
                <ProtectedRoute isLoggedIn={isLoggedIn}>
                  <FormWizardPage ... />
                </ProtectedRoute>
              } />
              {/* ... other protected routes ... */}

              {/* Catch-all: Redirect to landing page */}
              <Route path="*" element={<Navigate to="/" />} />
            </Routes>
          </div>
        </div>
      </div>
    </Router>
  );
}

export default App;
```

### B.2 ProtectedRoute Component (New)

```tsx
// src/components/ProtectedRoute.tsx
import React from 'react';
import { Navigate } from 'react-router-dom';

interface ProtectedRouteProps {
  children: React.ReactNode;
  isLoggedIn: boolean;
}

export const ProtectedRoute: React.FC<ProtectedRouteProps> = ({ children, isLoggedIn }) => {
  if (!isLoggedIn) {
    return <Navigate to="/" replace />;
  }

  return <>{children}</>;
};

export default ProtectedRoute;
```

### B.3 Updated LandingPage Component

**Current LandingPage** (to be updated):

```tsx
// src/pages/LandingPage.tsx (UPDATED)
import React from 'react';
import { useNavigate } from 'react-router-dom';
import { Slideshow } from '../components/Slideshow'; // Or similar existing component

interface LandingPageProps {
  onLoginSuccess?: () => void;
}

export const LandingPage: React.FC<LandingPageProps> = ({ onLoginSuccess }) => {
  const navigate = useNavigate();

  return (
    <div className="min-h-screen">
      {/* Slideshow takes full screen on landing */}
      <div className="h-screen">
        <Slideshow />
      </div>

      {/* Call-to-action section overlaid or below slideshow */}
      <div className="fixed bottom-0 left-0 right-0 p-6 bg-gradient-to-t from-black/50 to-transparent">
        <div className="max-w-7xl mx-auto flex gap-4 justify-center">
          <button
            onClick={() => navigate('/auth/register')}
            className="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
          >
            Create Account
          </button>
          <button
            onClick={() => navigate('/auth/login')}
            className="px-6 py-3 bg-gray-600 text-white rounded-lg hover:bg-gray-700 transition"
          >
            Sign In
          </button>
        </div>
      </div>

      {/* Or: Below slideshow */}
      <div className="bg-gray-900 text-white py-16 px-6 text-center">
        <h2 className="text-3xl font-bold mb-4">Join Knights & Kings</h2>
        <p className="mb-8 text-lg">Create your account or sign in to access the game.</p>
        <div className="flex gap-4 justify-center">
          <button
            onClick={() => navigate('/auth/register')}
            className="px-6 py-3 bg-blue-600 hover:bg-blue-700 rounded-lg transition"
          >
            Create Account
          </button>
          <button
            onClick={() => navigate('/auth/login')}
            className="px-6 py-3 bg-gray-600 hover:bg-gray-700 rounded-lg transition"
          >
            Sign In
          </button>
        </div>
      </div>
    </div>
  );
};
```

### B.4 Updated Navigation Component

```tsx
// src/components/Navigation.tsx (UPDATED)
import React from 'react';
import { useNavigate } from 'react-router-dom';
import { authService } from '../services/authService';

export interface ObjectType {
  id: string;
  label: string;
  icon: string;
  createRoute: string;
}

interface NavigationProps {
  objectTypes: ObjectType[];
}

export const Navigation: React.FC<NavigationProps> = ({ objectTypes }) => {
  const navigate = useNavigate();

  const handleLogout = async () => {
    try {
      await authService.logout();
      navigate('/'); // Redirect to landing page
      window.location.reload(); // Force reload to clear session
    } catch (error) {
      console.error('Logout failed:', error);
    }
  };

  return (
    <nav className="fixed top-0 left-0 right-0 bg-gray-800 text-white shadow-lg z-50">
      <div className="max-w-7xl mx-auto px-6 py-4 flex justify-between items-center">
        {/* Logo / Home */}
        <div
          className="text-xl font-bold cursor-pointer"
          onClick={() => navigate('/dashboard')}
        >
          Knights & Kings
        </div>

        {/* Menu Items */}
        <div className="flex gap-6 items-center">
          <button onClick={() => navigate('/dashboard')} className="hover:text-blue-400">
            Dashboard
          </button>
          <button onClick={() => navigate('/forms')} className="hover:text-blue-400">
            Forms
          </button>
          <button onClick={() => navigate('/admin/form-configurations')} className="hover:text-blue-400">
            Admin
          </button>

          {/* Logout Button */}
          <button
            onClick={handleLogout}
            className="px-4 py-2 bg-red-600 hover:bg-red-700 rounded transition"
          >
            Logout
          </button>
        </div>
      </div>
    </nav>
  );
};
```

### B.5 Loading Screen Component (New)

```tsx
// src/components/LoadingScreen.tsx (NEW)
import React from 'react';

export const LoadingScreen: React.FC = () => {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-100">
      <div className="text-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
        <p className="text-gray-700 text-lg">Loading...</p>
      </div>
    </div>
  );
};

export default LoadingScreen;
```

---

## Part C: User Flow Diagrams

### C.1 First-Time Visitor Flow

```
User visits website
  ↓
App checks session (useAutoLogin hook)
  ↓
No token found → Show Loading
  ↓
Landing Page with Slideshow
  ├─ [Create Account] button → Register Page
  └─ [Sign In] button → Login Page
```

### C.2 Returning User with "Remember Me" Flow

```
User visits website
  ↓
App checks session (useAutoLogin hook)
  ↓
Valid token in localStorage/cookie → Auto-login
  ↓
Silent redirect to Dashboard
  (No need to see landing page again)
```

### C.3 Invalid/Expired Token Flow

```
User visits website (with old token)
  ↓
App checks session (useAutoLogin hook)
  ↓
Token validation fails → Clear localStorage
  ↓
Landing Page with Slideshow (force re-login)
```

### C.4 User Tries to Access Protected Route Directly

```
User bookmarks: /dashboard or /forms
  ↓
User visits bookmark (without login)
  ↓
ProtectedRoute checks isLoggedIn
  ↓
isLoggedIn = false → Redirect to /
  ↓
Landing Page with Slideshow
```

---

## Part D: Session Management Detail

### D.1 Auto-Login Flow (Pseudocode)

```typescript
// useAutoLogin.ts - Runs once on App mount

1. Check if auth token exists in localStorage or cookie
   ├─ If NOT found: setIsLoggedIn(false), continue
   └─ If FOUND: proceed to step 2

2. Validate token with backend (POST /api/auth/validate-token)
   ├─ If 200 OK: Token is valid
   │   ├─ setIsLoggedIn(true)
   │   ├─ Store user context
   │   └─ (Component redirects to /dashboard if on landing)
   │
   ├─ If 401 Unauthorized: Token expired
   │   ├─ Clear localStorage/cookies
   │   ├─ setIsLoggedIn(false)
   │   └─ Show landing page
   │
   └─ If Network Error: Assume not logged in
       ├─ setIsLoggedIn(false)
       └─ Show landing page

3. Set isCheckingSession(false) → Hide loading spinner
```

### D.2 Token Lifecycle

```
User Registration:
  ├─ POST /api/users → Creates user
  ├─ Backend returns: { token, user, expiresIn }
  ├─ Frontend stores: token + user info
  └─ No remember me (new users should log in again)

User Login with "Remember Me" OFF:
  ├─ POST /api/auth/login → Validates credentials
  ├─ Backend returns: { token, user, expiresIn }
  ├─ Frontend stores: token in sessionStorage (cleared on close)
  └─ Duration: Session only (browser close = logout)

User Login with "Remember Me" ON:
  ├─ POST /api/auth/login { rememberMe: true } → Validates credentials
  ├─ Backend returns: { token, user, expiresIn }
  ├─ Backend sets httpOnly cookie with 30-day expiry
  ├─ Frontend stores: token + session expiry in localStorage
  └─ Duration: 30 days (or until manual logout)

Token Refresh (Optional - Future):
  ├─ If token expiring soon (< 5 min left)
  ├─ POST /api/auth/refresh-token → Get new token
  ├─ Silently update stored token
  └─ Continue without logout

User Logout:
  ├─ User clicks "Logout" button
  ├─ Frontend: Clear localStorage/sessionStorage
  ├─ Frontend: Clear httpOnly cookies (backend can help)
  ├─ Frontend: setIsLoggedIn(false)
  └─ Redirect to landing page
```

---

## Part E: Auth Routes Detail

### E.1 Public Routes (No Authentication Required)

| Route | Component | Purpose |
|-------|-----------|---------|
| `/` | `LandingPage` | Landing with slideshow + CTA buttons |
| `/auth/register` | `RegisterPage` | 3-step registration form |
| `/auth/login` | `LoginPage` | Email/password login + Remember Me |
| `/auth/register-success` | `RegisterSuccessPage` | Show link code + next steps |

### E.2 Protected Routes (Requires Login)

| Route | Component | Purpose |
|-------|-----------|---------|
| `/dashboard` | `ObjectDashboard` | Main dashboard (PROTECTED) |
| `/forms` | `FormWizardPage` | Entity forms (PROTECTED) |
| `/forms/:entityName` | `FormWizardPage` | Create form (PROTECTED) |
| `/forms/:entityName/edit/:id` | `FormWizardPage` | Edit entity (PROTECTED) |
| `/admin/form-configurations` | `FormConfigListPage` | Admin panel (PROTECTED) |
| `/admin/*` | Various | All admin routes (PROTECTED) |
| `/towns/create` | `TownCreateWizardPage` | Town creation (PROTECTED) |
| `/display/:entityName/:id` | `DisplayWizardPage` | Entity display (PROTECTED) |

---

## Part F: Error Handling & Edge Cases

### F.1 Network Error During Session Check

**Scenario**: Auto-login tries to validate token but network is down

**Behavior**:
```typescript
// useAutoLogin.ts
try {
  const isValid = await validateToken(token);
  // ...
} catch (error) {
  // Network error - assume not logged in for safety
  setIsLoggedIn(false);
  showError('Network error. Please check your connection.');
}
```

**User Experience**:
- Show landing page
- Display error message: "Network error. Please try again."
- Allow manual retry

### F.2 Token Expiry During Navigation

**Scenario**: User navigates while token expires

**Behavior**:
```typescript
// In component during navigation
try {
  await apiCall();
} catch (error) {
  if (error.status === 401) {
    // Token expired during operation
    authService.logout();
    navigate('/');
  }
}
```

---

## Part G: Migration Checklist

### From Current App.tsx to New Structure

- [ ] **Add `useAutoLogin` hook** to App component
- [ ] **Add `LoadingScreen`** component
- [ ] **Add `ProtectedRoute`** component wrapper
- [ ] **Reorganize routes**:
  - [ ] Move public routes to top
  - [ ] Wrap protected routes with `ProtectedRoute`
  - [ ] Add catch-all redirect to "/"
- [ ] **Update Navigation**:
  - [ ] Add conditional rendering: `{isLoggedIn && <Navigation />}`
  - [ ] Add "Logout" button to Navigation
  - [ ] Update navigation to be fixed/sticky only when logged in
- [ ] **Update LandingPage**:
  - [ ] Add CTA buttons for Sign Up / Login
  - [ ] Ensure Slideshow component is visible
  - [ ] Add responsive layout for mobile
- [ ] **Update styling**:
  - [ ] Conditional padding/margin based on nav visibility
  - [ ] Landing page full-screen Slideshow
  - [ ] Responsive button layout
- [ ] **Testing**:
  - [ ] Test first-time visitor flow
  - [ ] Test returning user with "Remember Me"
  - [ ] Test expired token redirect
  - [ ] Test direct navigation to protected routes
  - [ ] Test logout flow

---

## Part H: Example Updated App.tsx

```tsx
// src/App.tsx (COMPLETE UPDATE)
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { Navigation } from './components/Navigation';
import { LandingPage } from './pages/LandingPage';
import { useAutoLogin } from './hooks/useAutoLogin';
import { LoadingScreen } from './components/LoadingScreen';
import ProtectedRoute from './components/ProtectedRoute';
import ObjectDashboard from './components/ObjectDashboard';
import { objectConfigs } from './config/objectConfigs';
import { ErrorColor, logging } from './utils';
import en from './utils/languages/en-en.json';
import { ErrorView } from './components/ErrorView';
import { FormWizardPage } from './pages/FormWizardPage';
import { FormConfigBuilder } from './components/FormConfigBuilder/FormConfigBuilder';
import { FormConfigListPage } from './pages/FormConfigListPage';
import { DisplayWizardPage } from './pages/DisplayWizardPage';
import { DisplayConfigBuilder } from './components/DisplayConfigBuilder/DisplayConfigBuilder';
import { DisplayConfigListPage } from './pages/DisplayConfigListPage';
import { TownCreateWizardPage } from './pages/TownCreateWizardPage';
import React, { useRef } from 'react';
import { Subscription } from 'rxjs/internal/Subscription';

// Import auth pages (NEW)
import { RegisterPage } from './pages/auth/RegisterPage';
import { LoginPage } from './pages/auth/LoginPage';
import { RegisterSuccessPage } from './pages/auth/RegisterSuccessPage';

function App() {
  // Auto-login check on app load (NEW)
  const { isCheckingSession, isLoggedIn } = useAutoLogin();

  // Show loading while checking session
  if (isCheckingSession) {
    return <LoadingScreen />;
  }

  const errorContent = useRef<any[]>([]);
  let loggingErrorHandler: Subscription | null = null;

  const removeError = (value: string) => {
    const errorContentWithRemovedItem = errorContent.current.filter(
      (x) => x.content.props.content !== value
    );
    setTimeout(() => {
      errorContent.current = errorContentWithRemovedItem;
      clearTimeout(0);
    }, 0);
  };

  const initialize = () => {
    loggingErrorHandler = logging.errorHandler.subscribe((data: any) => {
      const message = getMessageFromPath(String(data)) ?? String(data);
      const errorMap = errorContent.current.map((x) => x.content.props.content);

      const isRed = data.includes('Red');

      if (errorMap.includes(message) === false) {
        const interval = setTimeout(() => {
          errorContent.current.shift();
          clearTimeout(interval);
        }, isRed ? 20000 : 6000);

        errorContent.current.push({
          content: (
            <ErrorView
              content={message}
              color={isRed ? ErrorColor.Red : ErrorColor.Grey}
              removeCallback={() => removeError(message)}
            />
          ),
        });
      }
    });
  };

  function getMessageFromPath(path: string): string | undefined {
    if (!path) return undefined;
    const parts = path.split('.').filter(Boolean);
    let current: any = en;
    for (const part of parts) {
      if (current && Object.prototype.hasOwnProperty.call(current, part)) {
        current = current[part];
      } else {
        return undefined;
      }
    }
    return typeof current === 'string' ? current : undefined;
  }

  const objectTypes = Object.entries(objectConfigs).map(([type, config]) => ({
    id: type,
    label: config.label,
    icon: config.icon,
    createRoute: `/forms/${type}`,
  }));

  React.useEffect(() => {
    initialize();

    return () => {
      loggingErrorHandler?.unsubscribe();
    };
  }, []);

  return (
    <Router>
      <div className="min-h-screen bg-gray-100">
        {/* Navigation only shows if logged in (NEW) */}
        {isLoggedIn && <Navigation objectTypes={objectTypes} />}

        {/* Main content with conditional padding (NEW) */}
        <div className={isLoggedIn ? 'pt-16 p-8' : ''}>
          <div className={isLoggedIn ? 'max-w-7xl mx-auto space-y-12' : ''}>
            <Routes>
              {/* PUBLIC ROUTES (Always accessible) */}
              <Route path="/" element={<LandingPage />} />
              <Route path="/auth/register" element={<RegisterPage />} />
              <Route path="/auth/login" element={<LoginPage />} />
              <Route path="/auth/register-success" element={<RegisterSuccessPage />} />

              {/* PROTECTED ROUTES (Only after login) */}
              <Route
                path="/dashboard"
                element={
                  <ProtectedRoute isLoggedIn={isLoggedIn}>
                    <ObjectDashboard objectTypes={objectTypes} />
                  </ProtectedRoute>
                }
              />
              <Route
                path="/forms"
                element={
                  <ProtectedRoute isLoggedIn={isLoggedIn}>
                    <FormWizardPage
                      entityTypeName=""
                      objectTypes={objectTypes}
                      autoOpenDefaultForm={false}
                    />
                  </ProtectedRoute>
                }
              />
              <Route
                path="/forms/:entityName"
                element={
                  <ProtectedRoute isLoggedIn={isLoggedIn}>
                    <FormWizardPage
                      entityTypeName=""
                      objectTypes={objectTypes}
                      autoOpenDefaultForm={false}
                    />
                  </ProtectedRoute>
                }
              />
              <Route
                path="/forms/:entityName/edit/:entityId"
                element={
                  <ProtectedRoute isLoggedIn={isLoggedIn}>
                    <FormWizardPage
                      entityTypeName=""
                      objectTypes={objectTypes}
                      autoOpenDefaultForm={false}
                    />
                  </ProtectedRoute>
                }
              />
              <Route
                path="/admin/form-configurations"
                element={
                  <ProtectedRoute isLoggedIn={isLoggedIn}>
                    <FormConfigListPage />
                  </ProtectedRoute>
                }
              />
              <Route
                path="/admin/form-configurations/new"
                element={
                  <ProtectedRoute isLoggedIn={isLoggedIn}>
                    <FormConfigBuilder />
                  </ProtectedRoute>
                }
              />
              <Route
                path="/admin/form-configurations/edit/:id"
                element={
                  <ProtectedRoute isLoggedIn={isLoggedIn}>
                    <FormConfigBuilder />
                  </ProtectedRoute>
                }
              />
              <Route
                path="/towns/create"
                element={
                  <ProtectedRoute isLoggedIn={isLoggedIn}>
                    <TownCreateWizardPage />
                  </ProtectedRoute>
                }
              />
              <Route
                path="/admin/display-configurations"
                element={
                  <ProtectedRoute isLoggedIn={isLoggedIn}>
                    <DisplayConfigListPage />
                  </ProtectedRoute>
                }
              />
              <Route
                path="/admin/display-configurations/new"
                element={
                  <ProtectedRoute isLoggedIn={isLoggedIn}>
                    <DisplayConfigBuilder />
                  </ProtectedRoute>
                }
              />
              <Route
                path="/admin/display-configurations/edit/:id"
                element={
                  <ProtectedRoute isLoggedIn={isLoggedIn}>
                    <DisplayConfigBuilder />
                  </ProtectedRoute>
                }
              />
              <Route
                path="/display/:entityName/:id"
                element={
                  <ProtectedRoute isLoggedIn={isLoggedIn}>
                    <DisplayWizardPage />
                  </ProtectedRoute>
                }
              />

              {/* Catch-all: Redirect to landing page */}
              <Route path="*" element={<Navigate to="/" replace />} />
            </Routes>
          </div>
        </div>
      </div>
    </Router>
  );
}

export default App;
```

---

## Part I: Summary of Changes

### Files to Create
1. `src/components/ProtectedRoute.tsx` - Protected route wrapper
2. `src/components/LoadingScreen.tsx` - Loading spinner
3. `src/pages/auth/RegisterPage.tsx` - Registration page
4. `src/pages/auth/LoginPage.tsx` - Login page
5. `src/pages/auth/RegisterSuccessPage.tsx` - Success page
6. `src/pages/auth/index.ts` - Barrel export
7. `src/components/auth/*` - Auth form components (from Phase 2)

### Files to Update
1. `src/App.tsx` - Main routing/layout restructuring
2. `src/pages/LandingPage.tsx` - Add CTA buttons, improve layout
3. `src/components/Navigation.tsx` - Add logout button, conditional render
4. `src/hooks/useAutoLogin.ts` - Auto-login on mount (from Phase 1)

### No Changes Needed
- Existing protected route components (Dashboard, Forms, etc.)
- Existing error handling
- Existing styling system

---

**Status**: ✅ Ready for Implementation  
**Document Version**: 1.0  
**Last Updated**: January 16, 2026
