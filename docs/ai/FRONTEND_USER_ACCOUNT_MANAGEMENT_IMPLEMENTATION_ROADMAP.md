# Frontend User Account Management - Implementation Roadmap

**Status**: Ready for Implementation  
**Created**: January 16, 2026  
**Last Updated**: January 16, 2026

---

## Executive Summary

This document provides a step-by-step implementation plan for user account creation, login, and session management in the knk-web-app frontend. It is derived from:
- [SPEC_USER_ACCOUNT_MANAGEMENT.md](../spec/SPEC_USER_ACCOUNT_MANAGEMENT.md)
- [FRONTEND_USER_ACCOUNT_MANAGEMENT_REQUIREMENTS.md](./FRONTEND_USER_ACCOUNT_MANAGEMENT_REQUIREMENTS.md)
- Analysis of existing web app architecture and component patterns

**Key Decisions** (Confirmed):
- ✅ Multi-step form (3-step registration)
- ✅ Remember Me: 30 days (industry standard for MMORPGs, user-friendly)
- ✅ httpOnly cookies for token storage
- ✅ Password strength meter with OWASP-aligned validation (8-128 chars, weak password blacklist)
- ✅ Client-side weak password detection
- ✅ Auto-login on page load (silent if valid token)
- ✅ Email verification after 3 failed login attempts

---

## Part A: Web App Architecture Analysis

### A.1 Current Structure & Patterns

**Folder Organization** (`src/`):
```
apiClients/     → API client implementations (pattern: entityClient.ts)
components/     → React components (organized by feature)
pages/          → Page-level components (routes)
services/       → Shared services (serviceCall.ts for API invocation)
types/          → TypeScript interfaces (dtos/, domain/)
utils/          → Utility functions, helpers, constants
```

**Key Observations**:

1. **API Client Pattern**:
   - Each entity has a dedicated client (e.g., `townClient.ts`, `streetClient.ts`)
   - Pattern: `export const entityClient = new SomeClient();`
   - Uses `ServiceCall.invokeApiService()` for HTTP calls
   - All clients are singletons exported from `apiClients/`

2. **FormWizard Component** (Multi-step form already exists):
   - Handles complex multi-step forms
   - Features: step validation, progress tracking, error handling, field rendering
   - Uses `FormConfigurationDto` to define form structure
   - Integrates with `FeedbackModal` for success/error messages
   - Props support: `onComplete`, `entityId`, workflow integration
   - **Reusable for authentication forms!**

3. **Error Handling**:
   - `ErrorView` component for displaying errors
   - Global logging system (`logging.errorHandler`)
   - `FeedbackModal` for transient messages

4. **Routing** (App.tsx):
   - Uses React Router v6
   - Current routes are dashboard-based (forms, admin, town create)
   - **Missing**: Auth routes, protected routes

5. **Styling**:
   - Tailwind CSS (class names visible in App.tsx)
   - No global stylesheet override needed

### A.2 Component Reuse Opportunities

| Existing Component | Reuse Potential | Recommendation |
|---|---|---|
| **FormWizard** | HIGH | Extend or create `AuthFormWizard` wrapper for registration (3-step) |
| **FeedbackModal** | HIGH | Use for success/error messages after registration/login |
| **ErrorView** | HIGH | Use for validation errors during form entry |
| **Navigation** | MEDIUM | Extend to show/hide auth buttons based on login state |
| **FieldRenderer** (FormWizard) | MEDIUM | Extract for reuse in auth forms if needed |
| **DynamicForm** | LOW | Use if simpler single-form login needed (but 3-step required) |

### A.3 Design Patterns to Follow

1. **API Client Singleton Pattern**:
   ```typescript
   // Create: src/apiClients/authClient.ts
   export const authClient = new AuthClient();
   
   // Use in components:
   import { authClient } from '../apiClients/authClient';
   const response = await authClient.register(formData);
   ```

2. **Service Call Pattern**:
   ```typescript
   const serviceCall = new ServiceCall();
   await serviceCall.invokeApiService({
     controller: 'users',
     operation: 'register',
     httpMethod: HttpMethod.Post,
     requestData: formData
   });
   ```

3. **Component Organization**:
   - Feature-based folders (e.g., `components/auth/`)
   - Export index.ts for clean imports
   - Props interfaces defined at top of file

4. **Type Organization**:
   - DTOs in `types/dtos/` by feature
   - Domain models in `types/domain/`
   - Common types in `types/common.ts`

5. **Error Handling**:
   - Catch errors in components
   - Use `logging.errorHandler` for global display
   - Pass specific error messages to `FeedbackModal`

---

## Part B: Updated Requirements (Per Your Answers)

### B.1 Landing Page & Navigation

**New Behavior** (Key Change):
1. Landing page with Slideshow component **always visible**
2. Navigation buttons hidden **until user logs in**
3. Login/Register links only shown on landing page
4. After login: Navigation shows, landing page accessible via breadcrumb/logo

**Implementation**:
```tsx
// App.tsx
function App() {
  const [isLoggedIn, setIsLoggedIn] = useState(false);

  return (
    <Router>
      <div className="min-h-screen bg-gray-100">
        {/* Navigation only shows if logged in */}
        {isLoggedIn && <Navigation ... />}
        
        <Routes>
          {/* Landing page always accessible */}
          <Route path="/" element={<LandingPage onLoginSuccess={() => setIsLoggedIn(true)} />} />
          
          {/* Auth routes (public) */}
          <Route path="/auth/register" element={<RegisterPage onRegisterSuccess={() => setIsLoggedIn(true)} />} />
          <Route path="/auth/login" element={<LoginPage onLoginSuccess={() => setIsLoggedIn(true)} />} />
          
          {/* Protected routes (requires login) */}
          <Route path="/dashboard" element={
            isLoggedIn ? <ObjectDashboard ... /> : <Navigate to="/" />
          } />
          {/* ... other protected routes ... */}
        </Routes>
      </div>
    </Router>
  );
}
```

**Landing Page Considerations**:
- Existing `LandingPage.tsx` likely has Slideshow
- Add call-to-action buttons: "Sign Up" and "Log In"
- Redirect to `/auth/register` or `/auth/login`

### B.2 Remember Me: 30 Days

**Standard for MMORPGs**:
- Typical: 14-30 days
- Extended: 30-60 days (less secure but user-friendly)
- Your choice: **30 days** for balance

**Implementation**:
```typescript
// authService.ts
const REMEMBER_ME_DURATION = 30 * 24 * 60 * 60 * 1000; // 30 days in ms

async function login(email: string, password: string, rememberMe: boolean) {
  const response = await authClient.login({ email, password, rememberMe });
  
  if (rememberMe) {
    // Backend sets httpOnly cookie with 30-day expiry
    // Frontend stores session metadata
    const expiryTime = new Date().getTime() + REMEMBER_ME_DURATION;
    localStorage.setItem('session-expiry', expiryTime.toString());
  }
  
  return response;
}
```

### B.3 Password Strength Meter (Updated)

**Backend Requirements** (from SPEC_USER_ACCOUNT_MANAGEMENT.md):
- Minimum: **8 characters**
- Maximum: **128 characters**
- **No forced complexity** (uppercase/numbers/symbols optional)
- **Blacklist**: Top 1000 compromised passwords + common patterns
- Rationale: OWASP recommends length over complexity

**Frontend Strength Calculation**:
```typescript
// Weak (0-1 points): < 8 chars, dictionary word
// Fair (2 points): 8-11 chars, no patterns
// Good (3 points): 12-15 chars, mixed case
// Strong (4 points): 16+ chars, mixed case + numbers
// Excellent (5 points): 20+ chars, mixed case + numbers + symbols

export interface PasswordStrength {
  score: 0 | 1 | 2 | 3 | 4 | 5;
  label: string;
  color: string; // 'red', 'orange', 'yellow', 'light-green', 'green'
  feedback: string[];
}

export function calculatePasswordStrength(password: string): PasswordStrength {
  if (!password) return { score: 0, label: 'Too short', color: 'red', feedback: [] };
  
  let score = 0;
  const feedback: string[] = [];

  // Check length
  if (password.length >= 8) score += 1;
  if (password.length >= 12) score += 1;
  if (password.length >= 16) score += 1;

  // Check variety
  if (/[a-z]/.test(password) && /[A-Z]/.test(password)) score += 1; // Mixed case
  if (/[0-9]/.test(password)) score += 0.5; // Numbers (optional but good)
  if (/[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(password)) score += 0.5; // Symbols (optional)

  // Check for weak patterns
  if (isWeakPassword(password)) {
    score = Math.max(0, score - 2); // Penalize common passwords
    feedback.push('This password appears in compromised password lists');
  }

  // Check for keyboard patterns
  if (hasKeyboardPattern(password)) {
    score = Math.max(0, score - 1);
    feedback.push('Avoid keyboard patterns (qwerty, asdf, etc.)');
  }

  // Check for sequential/repeated
  if (hasSequentialChars(password)) {
    score = Math.max(0, score - 1);
    feedback.push('Avoid sequential characters (123, abc, etc.)');
  }

  // Map score to label & color
  const strengthMap = [
    { label: 'Very Weak', color: '#dc2626' },      // Red
    { label: 'Weak', color: '#ea580c' },           // Orange
    { label: 'Fair', color: '#eab308' },           // Yellow
    { label: 'Good', color: '#84cc16' },           // Light Green
    { label: 'Strong', color: '#22c55e' },         // Green
    { label: 'Very Strong', color: '#16a34a' }     // Dark Green
  ];

  const finalScore = Math.min(5, Math.ceil(score));
  const strength = strengthMap[finalScore];

  return {
    score: finalScore as any,
    label: strength.label,
    color: strength.color,
    feedback
  };
}

function isWeakPassword(password: string): boolean {
  const weak = new Set([
    '123456', '123456789', '12345678', 'password', 'qwerty',
    // ... top 1000 from backend spec
  ]);
  return weak.has(password.toLowerCase());
}

function hasKeyboardPattern(password: string): boolean {
  const patterns = ['qwerty', 'asdf', 'zxcv', 'qazwsx', '12345', '98765'];
  return patterns.some(p => password.toLowerCase().includes(p));
}

function hasSequentialChars(password: string): boolean {
  for (let i = 0; i < password.length - 2; i++) {
    if (password.charCodeAt(i + 1) === password.charCodeAt(i) + 1 &&
        password.charCodeAt(i + 2) === password.charCodeAt(i + 1) + 1) {
      return true;
    }
  }
  return false;
}
```

**Visual Component**:
```tsx
export const PasswordStrengthMeter: React.FC<{ password: string }> = ({ password }) => {
  const strength = calculatePasswordStrength(password);

  return (
    <div className="space-y-2">
      <div className="flex gap-1">
        {Array.from({ length: 5 }).map((_, i) => (
          <div
            key={i}
            className={`h-2 flex-1 rounded ${
              i < strength.score ? '' : 'bg-gray-300'
            }`}
            style={{ backgroundColor: i < strength.score ? strength.color : undefined }}
          />
        ))}
      </div>
      <div className="text-sm">
        <span style={{ color: strength.color }}>{strength.label}</span>
      </div>
      {strength.feedback.length > 0 && (
        <ul className="text-xs text-gray-600 list-disc list-inside">
          {strength.feedback.map((f, i) => <li key={i}>{f}</li>)}
        </ul>
      )}
    </div>
  );
};
```

### B.4 Auto-Login on Page Load

**Implementation**:
```typescript
// hooks/useAuth.ts
export function useAutoLogin(): { isLoading: boolean; isLoggedIn: boolean } {
  const [isLoading, setIsLoading] = useState(true);
  const [isLoggedIn, setIsLoggedIn] = useState(false);

  useEffect(() => {
    const checkSession = async () => {
      try {
        // Check if token exists and is valid
        const token = localStorage.getItem('auth-token');
        if (!token) {
          setIsLoggedIn(false);
          setIsLoading(false);
          return;
        }

        // Validate token with backend
        const isValid = await authService.validateToken(token);
        if (isValid) {
          setIsLoggedIn(true);
        } else {
          // Token expired; clear and logout
          localStorage.clear();
          setIsLoggedIn(false);
        }
      } catch (error) {
        console.error('Auto-login failed:', error);
        setIsLoggedIn(false);
      } finally {
        setIsLoading(false);
      }
    };

    checkSession();
  }, []);

  return { isLoading, isLoggedIn };
}

// App.tsx usage
function App() {
  const { isLoading, isLoggedIn } = useAutoLogin();

  if (isLoading) {
    return <LoadingScreen />; // Show spinner while checking session
  }

  return (
    // ... routing with isLoggedIn state
  );
}
```

### B.5 Email Verification After 3 Failed Attempts

**New Flow**:
```
User enters wrong credentials 3 times
  ↓
System shows: "Too many login attempts. A verification link has been sent to your email."
  ↓
Optionally: Show email input field to resend verification code
  ↓
User clicks link in email
  ↓
Email verified; unlock account
```

**Implementation Phase**: Phase 4 (Advanced) - not required for initial launch

---

## Part C: Implementation Phases

### Phase 1: Foundation & API Client (3-4 days)

**Deliverables**:
- [ ] Create `authClient.ts` (follows existing pattern)
- [ ] Create `src/types/dtos/auth/` directory
- [ ] Define TypeScript DTOs: `UserDtos.ts`, `AuthDtos.ts`
- [ ] Create `authService.ts` in `src/services/`
- [ ] Create `useAuth.ts` hook for auth state
- [ ] Add session/token management utilities
- [ ] Update `App.tsx` routing structure

**Files to Create**:
```
src/
├── apiClients/authClient.ts (NEW)
├── types/dtos/auth/
│   └── UserDtos.ts (NEW)
│   └── AuthDtos.ts (NEW)
├── services/authService.ts (NEW)
├── hooks/useAuth.ts (NEW)
└── utils/tokenService.ts (NEW)
```

**Key Tasks**:

1. **Create AuthClient** (`apiClients/authClient.ts`):
   ```typescript
   export class AuthClient {
     async register(data: RegisterRequestDto): Promise<RegisterResponseDto> {
       // Use ServiceCall pattern
     }

     async login(data: LoginRequestDto): Promise<AuthResponseDto> {
       // ...
     }

     async validateToken(token: string): Promise<boolean> {
       // ...
     }

     async generateLinkCode(userId: number): Promise<LinkCodeDto> {
       // ...
     }
   }

   export const authClient = new AuthClient();
   ```

2. **Define DTOs** (`types/dtos/auth/AuthDtos.ts`):
   - `RegisterRequestDto`
   - `RegisterResponseDto`
   - `LoginRequestDto`
   - `AuthResponseDto`
   - `LinkCodeDto`
   - `FieldValidationErrorDto`
   - `PasswordStrengthDto`

3. **Create AuthService** (`services/authService.ts`):
   - Wrapper around authClient
   - Token storage/retrieval logic
   - Session validation
   - Auto-login logic

4. **Update App.tsx**:
   - Add auth routing
   - Add protected route wrapper
   - Add auto-login hook
   - Hide navigation until login

**Estimated Effort**: 12-16 hours

---

### Phase 2: Registration Form (4-5 days)

**Deliverables**:
- [ ] Create `RegisterPage.tsx` container
- [ ] Create `RegisterForm.tsx` (multi-step wrapper)
- [ ] Create `FormStep1.tsx` (email, password)
- [ ] Create `FormStep2.tsx` (username)
- [ ] Create `FormStep3.tsx` (review & confirm)
- [ ] Create `PasswordStrengthMeter.tsx` component
- [ ] Integrate with FormWizard or create custom AuthFormWizard
- [ ] Add real-time validation
- [ ] Add error handling

**Files to Create**:
```
src/
├── pages/auth/
│   ├── RegisterPage.tsx (NEW)
│   ├── RegisterSuccessPage.tsx (NEW)
│   └── index.ts (NEW)
└── components/auth/
    ├── RegisterForm.tsx (NEW)
    ├── FormStep1.tsx (NEW)
    ├── FormStep2.tsx (NEW)
    ├── FormStep3.tsx (NEW)
    ├── PasswordStrengthMeter.tsx (NEW)
    ├── FormStepper.tsx (NEW)
    └── index.ts (NEW)
```

**Key Tasks**:

1. **RegisterPage.tsx**: Wrapper page with error handling
2. **RegisterForm.tsx**: Multi-step container with step navigation
3. **FormStep1.tsx**: Email & password inputs with real-time validation
4. **FormStep2.tsx**: Username input with availability check
5. **FormStep3.tsx**: Review form data before submission
6. **PasswordStrengthMeter.tsx**: Visual password strength indicator

**Reuse**:
- Use `FeedbackModal` for success/error messages
- Use `ErrorView` for validation errors
- Consider extending `FormWizard` component for multi-step logic
- Use existing Tailwind classes from app

**Validation**:
- Email: Format check, availability check (API call)
- Password: Strength meter, 8-128 chars, weak password blacklist
- Username: Format check (alphanumeric + underscore, 3-16 chars), availability check

**API Integration**:
- POST `/api/users/register` on step 3 submit
- GET `/api/users/check-duplicate` for email/username availability
- Handle 409 Conflict for duplicates

**Estimated Effort**: 16-20 hours

---

### Phase 3: Login Form (3-4 days)

**Deliverables**:
- [ ] Create `LoginPage.tsx` container
- [ ] Create `LoginForm.tsx` with email/password
- [ ] Add "Remember Me" checkbox
- [ ] Add "Show/Hide password" toggle
- [ ] Implement auto-login on page load
- [ ] Add error handling for invalid credentials
- [ ] Add loading states

**Files to Create**:
```
src/
├── pages/auth/
│   └── LoginPage.tsx (NEW)
└── components/auth/
    └── LoginForm.tsx (NEW)
```

**Key Tasks**:

1. **LoginPage.tsx**: Wrapper with auto-login redirect
2. **LoginForm.tsx**: Email/password form with remember me
3. **useAutoLogin.ts**: Hook to check session on app load
4. **Remember Me Logic**: 30-day httpOnly cookie
5. **Error Handling**: Show specific errors (wrong credentials, server error, etc.)
6. **Auto-redirect**: If already logged in, redirect to dashboard

**API Integration**:
- POST `/api/auth/login` with email, password, rememberMe flag
- Handle 401 Unauthorized for invalid credentials
- Store JWT token in httpOnly cookie + localStorage
- Validate token on auto-login

**Estimated Effort**: 12-16 hours

---

### Phase 4: Registration Success & Link Code (2-3 days)

**Deliverables**:
- [ ] Create `RegisterSuccessPage.tsx` component
- [ ] Display link code (ABC-12XYZ format)
- [ ] Add copy-to-clipboard functionality
- [ ] Show next steps (join Minecraft server, use /account link)
- [ ] Add auto-redirect to login

**Files to Create**:
```
src/
├── components/auth/
│   └── LinkCodeDisplay.tsx (NEW)
```

**Key Tasks**:

1. **RegisterSuccessPage.tsx**: Show link code and instructions
2. **LinkCodeDisplay.tsx**: Copy button, format display
3. **Auto-redirect**: After 3-5 seconds, redirect to login

**Estimated Effort**: 4-6 hours

---

### Phase 5: Polish & Accessibility (3-4 days)

**Deliverables**:
- [ ] WCAG 2.1 Level AA compliance
- [ ] Screen reader support
- [ ] Keyboard navigation
- [ ] Mobile responsiveness
- [ ] Error message accessibility (aria-describedby)
- [ ] Loading state announcements

**Key Tasks**:

1. Add `aria-label`, `aria-describedby` to form fields
2. Add `role="alert"` to error containers
3. Ensure focus management on form steps
4. Test keyboard navigation (Tab, Enter, Shift+Tab)
5. Test with screen reader (NVDA, VoiceOver)
6. Responsive layout for mobile (max 400px width)
7. Font size minimum 16px on inputs (prevent iOS zoom)

**Estimated Effort**: 8-12 hours

---

### Phase 6: Testing & Documentation (3-4 days)

**Deliverables**:
- [ ] Unit tests for validation logic
- [ ] Component tests for registration/login forms
- [ ] E2E tests (Cypress) for complete flows
- [ ] API integration tests
- [ ] Documentation for future developers

**Test Cases**:
1. **Registration**:
   - Valid registration with all fields
   - Duplicate email error (409)
   - Duplicate username error (409)
   - Weak password rejection
   - Password mismatch error
   - Invalid email format
   - Invalid username format
   - Success → link code display → auto-redirect to login

2. **Login**:
   - Valid login → redirect to dashboard
   - Invalid credentials → error message
   - Wrong password → error message
   - Remember Me → persist 30 days
   - Auto-login on page load
   - Session expiry → logout & redirect to login

3. **Auto-Login**:
   - Token valid → silent auto-login to dashboard
   - Token expired → clear & show login page
   - No token → show login page

**Estimated Effort**: 16-20 hours

---

## Part D: Total Effort Estimate

| Phase | Task | Hours | Days |
|-------|------|-------|------|
| 1 | Foundation & API Client | 12-16 | 1.5-2 |
| 2 | Registration Form | 16-20 | 2-2.5 |
| 3 | Login Form | 12-16 | 1.5-2 |
| 4 | Success & Link Code | 4-6 | 0.5-1 |
| 5 | Polish & Accessibility | 8-12 | 1-1.5 |
| 6 | Testing & Documentation | 16-20 | 2-2.5 |
| **Total** | | **68-90** | **8.5-11.5 days** |

**Timeline** (with team):
- 2 developers: 5-6 weeks
- 1 developer: 2-3 weeks (part-time) or 1-2 weeks (full-time with support)

---

## Part E: Component Reuse & Extension Strategy

### E.1 Reuse Opportunities

**FormWizard Extension** (Recommended):
```typescript
// Create: components/auth/AuthFormWizard.tsx
export const AuthFormWizard: React.FC<AuthFormWizardProps> = (props) => {
  // Wrapper around FormWizard with auth-specific configs
  // Handles: multi-step validation, password strength, username availability
  // Returns: automatically configured FormWizard
};
```

**FeedbackModal Reuse**:
```typescript
// Use existing component for:
// - Success messages (registration complete)
// - Error messages (duplicate email, weak password, etc.)
// - Info messages (link code expiry warning)

<FeedbackModal
  open={showSuccess}
  title="Account Created!"
  message="Your link code: ABC-12XYZ"
  status="success"
  onClose={handleClose}
/>
```

**ErrorView Reuse**:
```typescript
// Use for inline field-level errors
// Pattern already established in codebase

<ErrorView content={error} color={ErrorColor.Red} />
```

### E.2 New Component Hierarchy

```
src/
├── pages/
│   ├── auth/
│   │   ├── RegisterPage.tsx
│   │   ├── LoginPage.tsx
│   │   ├── RegisterSuccessPage.tsx
│   │   └── index.ts
│   └── LandingPage.tsx (update)
│
├── components/
│   ├── auth/
│   │   ├── RegisterForm.tsx (container)
│   │   ├── FormStep1.tsx (email, password)
│   │   ├── FormStep2.tsx (username)
│   │   ├── FormStep3.tsx (review)
│   │   ├── LoginForm.tsx
│   │   ├── PasswordStrengthMeter.tsx
│   │   ├── FormStepper.tsx
│   │   ├── LinkCodeDisplay.tsx
│   │   └── index.ts
│   ├── Navigation.tsx (update - hide/show based on login)
│   └── (existing components)
│
├── hooks/
│   ├── useAuth.ts (login, logout, getCurrentUser)
│   ├── useAutoLogin.ts (auto-login on page load)
│   ├── useFormValidation.ts (field validation)
│   └── useRememberMe.ts (session persistence)
│
├── services/
│   ├── authService.ts (auth logic)
│   ├── tokenService.ts (JWT handling)
│   └── serviceCall.ts (existing)
│
├── apiClients/
│   ├── authClient.ts (auth endpoints)
│   └── (existing clients)
│
├── types/
│   ├── dtos/
│   │   ├── auth/
│   │   │   ├── UserDtos.ts
│   │   │   └── AuthDtos.ts
│   │   └── (existing)
│   └── (existing)
│
└── utils/
    ├── passwordValidator.ts
    ├── validation.ts (field validators)
    └── (existing)
```

---

## Part F: Code Patterns & Examples

### F.1 AuthClient Pattern (Following Existing Code)

```typescript
// src/apiClients/authClient.ts
import { ServiceCall } from '../services/serviceCall';
import { HttpMethod } from '../utils/enums';
import {
  RegisterRequestDto,
  RegisterResponseDto,
  LoginRequestDto,
  AuthResponseDto,
} from '../types/dtos/auth/AuthDtos';
import ConfigurationHelper from '../utils/config-helper';

export class AuthClient {
  private serviceCall: ServiceCall;

  constructor() {
    this.serviceCall = new ServiceCall();
  }

  async register(data: RegisterRequestDto): Promise<RegisterResponseDto> {
    try {
      const response = await this.serviceCall.invokeApiService({
        controller: 'users',
        operation: 'register',
        httpMethod: HttpMethod.Post,
        requestData: data,
      });
      return response;
    } catch (error) {
      throw this.handleError(error);
    }
  }

  async login(data: LoginRequestDto): Promise<AuthResponseDto> {
    try {
      const response = await this.serviceCall.invokeApiService({
        controller: 'auth',
        operation: 'login',
        httpMethod: HttpMethod.Post,
        requestData: data,
      });
      return response;
    } catch (error) {
      throw this.handleError(error);
    }
  }

  async validateToken(token: string): Promise<boolean> {
    try {
      await this.serviceCall.invokeApiService({
        controller: 'auth',
        operation: 'validate-token',
        httpMethod: HttpMethod.Post,
        requestData: { token },
      });
      return true;
    } catch (error) {
      return false;
    }
  }

  async generateLinkCode(userId: number): Promise<{ code: string; expiresAt: string }> {
    try {
      const response = await this.serviceCall.invokeApiService({
        controller: 'users',
        operation: 'generate-link-code',
        httpMethod: HttpMethod.Post,
        requestData: { userId },
      });
      return response;
    } catch (error) {
      throw this.handleError(error);
    }
  }

  private handleError(error: any): Error {
    // Map backend error to user-friendly message
    if (error.status === 409) {
      return new Error('DuplicateEmail'); // Will be mapped by component
    }
    if (error.status === 401) {
      return new Error('InvalidCredentials');
    }
    return new Error('NetworkError');
  }
}

export const authClient = new AuthClient();
```

### F.2 AuthService Pattern

```typescript
// src/services/authService.ts
import { authClient } from '../apiClients/authClient';
import { LoginRequestDto, RegisterRequestDto } from '../types/dtos/auth/AuthDtos';

export class AuthService {
  private static readonly REMEMBER_ME_DURATION = 30 * 24 * 60 * 60 * 1000; // 30 days

  async register(data: RegisterRequestDto) {
    const response = await authClient.register(data);
    return response;
  }

  async login(email: string, password: string, rememberMe: boolean = false) {
    const response = await authClient.login({
      email,
      password,
      rememberMe,
    });

    // Store token
    this.storeToken(response.token, rememberMe);

    // Store user context
    localStorage.setItem('user', JSON.stringify(response.user));

    return response.user;
  }

  async validateToken(token: string): Promise<boolean> {
    return await authClient.validateToken(token);
  }

  async logout() {
    localStorage.clear();
    // Optional: notify backend
  }

  async autoLogin(): Promise<{ isValid: boolean; user?: any }> {
    const token = localStorage.getItem('auth-token');
    if (!token) {
      return { isValid: false };
    }

    try {
      const isValid = await this.validateToken(token);
      if (isValid) {
        const user = JSON.parse(localStorage.getItem('user') || '{}');
        return { isValid: true, user };
      }
    } catch (error) {
      localStorage.clear();
    }

    return { isValid: false };
  }

  private storeToken(token: string, rememberMe: boolean) {
    if (rememberMe) {
      // Backend sets httpOnly cookie
      const expiryTime = new Date().getTime() + AuthService.REMEMBER_ME_DURATION;
      localStorage.setItem('session-expiry', expiryTime.toString());
    }

    localStorage.setItem('auth-token', token);
  }
}

export const authService = new AuthService();
```

### F.3 useAuth Hook

```typescript
// src/hooks/useAuth.ts
import { useState, useCallback } from 'react';
import { authService } from '../services/authService';
import { RegisterRequestDto, LoginRequestDto } from '../types/dtos/auth/AuthDtos';

export function useAuth() {
  const [user, setUser] = useState(null);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const register = useCallback(async (data: RegisterRequestDto) => {
    setIsLoading(true);
    setError(null);
    try {
      const response = await authService.register(data);
      return response;
    } catch (err: any) {
      const errorMessage = err.message || 'Registration failed';
      setError(errorMessage);
      throw err;
    } finally {
      setIsLoading(false);
    }
  }, []);

  const login = useCallback(async (email: string, password: string, rememberMe: boolean = false) => {
    setIsLoading(true);
    setError(null);
    try {
      const user = await authService.login(email, password, rememberMe);
      setUser(user);
      return user;
    } catch (err: any) {
      const errorMessage = err.message || 'Login failed';
      setError(errorMessage);
      throw err;
    } finally {
      setIsLoading(false);
    }
  }, []);

  const logout = useCallback(async () => {
    setIsLoading(true);
    try {
      await authService.logout();
      setUser(null);
    } finally {
      setIsLoading(false);
    }
  }, []);

  return {
    user,
    isLoading,
    error,
    register,
    login,
    logout,
  };
}
```

### F.4 useAutoLogin Hook

```typescript
// src/hooks/useAutoLogin.ts
import { useEffect, useState } from 'react';
import { authService } from '../services/authService';

export function useAutoLogin() {
  const [isCheckingSession, setIsCheckingSession] = useState(true);
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [user, setUser] = useState(null);

  useEffect(() => {
    const checkSession = async () => {
      try {
        const { isValid, user: userData } = await authService.autoLogin();
        if (isValid) {
          setIsLoggedIn(true);
          setUser(userData);
        } else {
          setIsLoggedIn(false);
        }
      } catch (error) {
        console.error('Auto-login check failed:', error);
        setIsLoggedIn(false);
      } finally {
        setIsCheckingSession(false);
      }
    };

    checkSession();
  }, []);

  return { isCheckingSession, isLoggedIn, user };
}
```

---

## Part G: Database / API Alignment

**Backend Already Complete**:
- ✅ User model with new auth fields
- ✅ LinkCode entity
- ✅ Password & link code services
- ✅ API endpoints for register, login, validate-token, generate-link-code
- ✅ DTOs with proper error responses

**Frontend Must Integrate With**:
- `POST /api/users` - Register
- `POST /api/auth/login` - Login
- `POST /api/auth/validate-token` - Token validation
- `POST /api/users/generate-link-code` - Generate link code
- `POST /api/users/check-duplicate` - Check email/username availability

**Error Response Format** (Backend Already Returns):
```json
{
  "error": "ValidationFailed",
  "message": "Email already in use",
  "code": "DuplicateEmail"
}
```

Frontend must:
1. Map error codes to user-friendly messages
2. Handle 409 Conflict responses
3. Handle 401 Unauthorized responses
4. Display field-level validation errors

---

## Part H: Configuration & Constants

### H.1 Create `src/utils/authConstants.ts`

```typescript
export const AUTH_REMEMBER_ME_DURATION = 30 * 24 * 60 * 60 * 1000; // 30 days
export const PASSWORD_MIN_LENGTH = 8;
export const PASSWORD_MAX_LENGTH = 128;
export const USERNAME_MIN_LENGTH = 3;
export const USERNAME_MAX_LENGTH = 16;
export const LINK_CODE_EXPIRY_MINUTES = 20;

export const WEAK_PASSWORDS = new Set([
  '123456', '123456789', '12345678', 'password', 'qwerty',
  '111111', '123123', '1234567', 'dragon', 'baseball',
  // ... top 1000 from backend spec
]);

export const ERROR_MESSAGES: Record<string, string> = {
  DuplicateEmail: 'Email already registered. Try logging in or use a different email.',
  DuplicateUsername: 'Minecraft username already taken. Try a variation.',
  InvalidPassword: 'Password is too common. Choose something stronger.',
  PasswordMismatch: 'Passwords do not match.',
  InvalidEmail: 'Please enter a valid email address.',
  InvalidUsername: 'Username must be 3-16 alphanumeric characters.',
  LinkCodeExpired: 'Link code expired (valid for 20 minutes).',
  InvalidCredentials: 'Email or password is incorrect.',
  NetworkError: 'Network error. Please try again.',
  ServerError: 'Server error. Please try again later.',
};
```

---

## Part I: Testing Checklist

### Integration Tests

- [ ] Register new user → Success → Link code displayed
- [ ] Register duplicate email → 409 → Error message
- [ ] Register duplicate username → 409 → Error message
- [ ] Register weak password → Rejected before submit
- [ ] Password mismatch → Validation error before submit
- [ ] Login valid credentials → Token stored → Redirect to dashboard
- [ ] Login invalid email → 401 → Error message
- [ ] Login invalid password → 401 → Error message
- [ ] Remember me checked → Token persists 30 days
- [ ] Remember me unchecked → Token cleared on browser close
- [ ] Auto-login with valid token → Silent redirect to dashboard
- [ ] Auto-login with expired token → Redirect to login
- [ ] Copy link code button → Copied to clipboard

### E2E Tests (Cypress)

```typescript
describe('User Registration & Login', () => {
  it('completes registration flow', () => {
    cy.visit('/');
    cy.contains('Sign Up').click();
    cy.url().should('include', '/auth/register');
    
    // Step 1
    cy.get('[data-testid="email"]').type('test@example.com');
    cy.get('[data-testid="password"]').type('SecurePass123!');
    cy.get('[data-testid="confirm-password"]').type('SecurePass123!');
    cy.contains('Next').click();
    
    // Step 2
    cy.get('[data-testid="username"]').type('TestPlayer');
    cy.contains('Next').click();
    
    // Step 3
    cy.contains('Register').click();
    cy.contains('Account Created').should('be.visible');
    cy.get('[data-testid="link-code"]').should('contain', /[A-Z0-9]{3}-[A-Z0-9]{5}/);
  });

  it('completes login flow', () => {
    cy.visit('/auth/login');
    cy.get('[data-testid="email"]').type('test@example.com');
    cy.get('[data-testid="password"]').type('SecurePass123!');
    cy.get('[data-testid="remember-me"]').click();
    cy.contains('Sign In').click();
    cy.url().should('include', '/dashboard');
  });
});
```

---

## Part J: Next Steps

1. **Confirm Roadmap** - Get team sign-off on phases & timelines
2. **Setup Development** - Create feature branch, scaffold folders
3. **Start Phase 1** - API client & services
4. **Coordinate with Backend** - Ensure API endpoints match spec
5. **Design Review** - Validate UI mockups before Phase 2
6. **Implementation** - Follow phases in sequence
7. **Testing** - Write tests as you go (TDD recommended)
8. **Documentation** - Update README with auth flows

---

## Appendix A: File Structure Summary

```
src/
├── App.tsx (UPDATE: Add auth routes, protected routes, Navigation conditionally)
├── apiClients/
│   ├── authClient.ts (NEW)
│   └── (existing)
├── components/
│   ├── auth/ (NEW folder)
│   │   ├── RegisterForm.tsx
│   │   ├── FormStep1.tsx
│   │   ├── FormStep2.tsx
│   │   ├── FormStep3.tsx
│   │   ├── LoginForm.tsx
│   │   ├── PasswordStrengthMeter.tsx
│   │   ├── FormStepper.tsx
│   │   ├── LinkCodeDisplay.tsx
│   │   └── index.ts
│   ├── Navigation.tsx (UPDATE: Hide until login)
│   └── (existing)
├── hooks/
│   ├── useAuth.ts (NEW)
│   ├── useAutoLogin.ts (NEW)
│   └── (existing)
├── pages/
│   ├── auth/ (NEW folder)
│   │   ├── RegisterPage.tsx
│   │   ├── LoginPage.tsx
│   │   ├── RegisterSuccessPage.tsx
│   │   └── index.ts
│   ├── LandingPage.tsx (UPDATE: Always visible, add CTA buttons)
│   └── (existing)
├── services/
│   ├── authService.ts (NEW)
│   ├── tokenService.ts (NEW)
│   └── serviceCall.ts (existing)
├── types/
│   ├── dtos/
│   │   ├── auth/ (NEW folder)
│   │   │   ├── UserDtos.ts
│   │   │   └── AuthDtos.ts
│   │   └── (existing)
│   └── (existing)
└── utils/
    ├── authConstants.ts (NEW)
    ├── passwordValidator.ts (NEW)
    └── (existing)
```

---

**Status**: ✅ Ready for Implementation  
**Document Version**: 2.0 (Updated with Web App Analysis)  
**Last Updated**: January 16, 2026
