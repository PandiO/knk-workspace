# Frontend User Account Management Requirements

**Status**: Proposed  
**Created**: January 16, 2026  
**Last Updated**: January 16, 2026

---

## Executive Summary

This document specifies the frontend (React/TypeScript web app) requirements for user account creation, login, and session management. It is derived from the backend specification ([SPEC_USER_ACCOUNT_MANAGEMENT.md](../spec/SPEC_USER_ACCOUNT_MANAGEMENT.md)) and provides UI/UX flows, form requirements, validation rules, and technical implementation guidance.

**Key Features**:
- User registration (email, password, Minecraft username)
- User login (email & password)
- "Remember Me" session persistence
- Link code validation & account linking
- Password validation with real-time feedback
- Error handling and user notifications

---

## Part A: User Flows & Scenarios

### A.1 Primary User Flows

#### Flow 1A: New User Registration (Web App First)

```
User Action → System Response
─────────────────────────────────
1. User clicks "Sign Up" button → Show registration form
2. User enters email → Validate email format in real-time
3. User enters password → Show password strength meter
4. User enters password confirmation → Check match
5. User enters Minecraft username → Validate format
6. User clicks "Register" → 
   - Validate all fields
   - Check for duplicates (email, username)
   - Hash password on backend
   - Create user account
   - Generate link code
7. Show success page with:
   - Confirmation message
   - Link code displayed (ABC-12XYZ format)
   - Instructions: "You'll receive this code when you join the Minecraft server"
   - Option to copy code
   - Button to proceed to login or dashboard
```

**Suggested UX Enhancements**:
- [ ] **Multi-step form** (Visual stepper: Step 1/3 "Account Info" → Step 2/3 "Minecraft Info" → Step 3/3 "Review")
- [ ] **Progress indicators** showing validation status per field (✓ or ✗)
- [ ] **Inline help text** explaining link code purpose
- [ ] **Copy-to-clipboard button** for link code

---

#### Flow 1B: Existing User Login

```
User Action → System Response
─────────────────────────────────
1. User visits web app → Check session/token
   - If valid token found: Redirect to dashboard
   - If no token: Show login page
2. User enters email → Debounced validation
3. User enters password → No validation (user can enter anything)
4. [OPTIONAL] User checks "Remember Me" → Flag session
5. User clicks "Login" →
   - Submit credentials to backend
   - Backend validates & returns JWT token
   - Store token in localStorage/sessionStorage
   - If "Remember Me" checked: Persist session (14-day expiry suggested)
   - Redirect to dashboard
6. On future visits:
   - Check localStorage for token
   - If found & valid: Auto-login (silent)
   - If found & expired: Clear & show login page
```

**Suggested UX Enhancements**:
- [ ] **Persistent login** (30-day cookie + secure httpOnly flag)
- [ ] **"Forgot Password?" link** (if password reset implemented)
- [ ] **Show/hide password toggle** for better UX
- [ ] **Loading state** on submit button (disabled + spinner)
- [ ] **Social/OAuth login** (future; GitHub, Discord? TBD)

---

#### Flow 1C: Link Minecraft Account (Post-Registration)

```
When User Joins Minecraft Server:
─────────────────────────────────
1. Player joins server → Server checks UUID
2. Server sends: "Welcome! Your web account has a link code ready."
3. Player is NOT automatically linked yet
4. Player must use /account link ABC12XYZ on server
5. Server validates code with backend API
6. If valid:
   - Account linked (UUID recorded in user record)
   - Chat message: "✓ Accounts linked! Welcome to KnK."
   - Player can now access game features
7. If expired or invalid:
   - Chat message: "Link code expired. Go to web app and generate a new one."
   - Suggest user visit dashboard to generate new link code
```

**Frontend Support Needed**:
- [ ] **Dashboard link to "Generate Link Code"** for existing users
- [ ] **Display current Minecraft linking status** ("Linked as: PlayerName UUID: xyz...")
- [ ] **Button to generate new link code** (for re-linking or if expired)

---

### A.2 Error Scenarios

#### Scenario A2-1: Duplicate Email

```
User enters already-registered email → 
Backend returns 409 Conflict
Frontend shows:
  Error: "Email already in use"
  Suggestions:
    - "Already have an account? Log in here"
    - "Forgot password? Request a reset"
    - Contact support link
```

#### Scenario A2-2: Duplicate Username

```
User enters Minecraft username that's registered → 
Backend returns 409 Conflict
Frontend shows:
  Error: "Username is already taken"
  Help: "Minecraft usernames must be unique. 
         Try a variation or contact support if you think this is a mistake."
```

#### Scenario A2-3: Weak Password

```
User enters password (e.g., "123456" or "password") →
Backend rejects during registration
Frontend shows (could show pre-emptively too):
  Error: "Password is too common. Please choose a stronger one."
  Suggestions:
    - "Include mix of upper, lower, numbers? (optional but recommended)"
    - Show password strength meter BEFORE submission
```

#### Scenario A2-4: Invalid Email Format

```
User enters malformed email → 
Frontend real-time validation catches it
Show: "Please enter a valid email address (e.g., player@example.com)"
```

#### Scenario A2-5: Password Mismatch

```
User enters different password & confirmation →
Frontend real-time validation catches it
Show: "Passwords do not match"
```

#### Scenario A2-6: Link Code Expired

```
User tries to link Minecraft account with expired code →
Backend returns 400 Bad Request
Frontend shows:
  Error: "Link code expired (codes are valid for 20 minutes)"
  Action: "Generate a new code" [Button]
```

---

## Part B: Registration Form Specification

### B.1 Registration Page Layout

**Suggested Structure** (mobile-first):

```
┌─────────────────────────────────┐
│                                 │
│  Knights & Kings                │
│  Create Your Account            │
│                                 │
├─────────────────────────────────┤
│ STEP 1 OF 3: ACCOUNT INFO       │
├─────────────────────────────────┤
│                                 │
│  Email *                        │
│  [________@example.com________] │
│  ← Validation: Format check     │
│                                 │
│  Password *                     │
│  [_______________]  [👁 Show]  │
│  ← Strength: ████░ (4/5)        │
│  ← Min 8 chars, no complexity   │
│  ← Avoid: 123456, qwerty, etc.  │
│                                 │
│  Confirm Password *             │
│  [_______________]  [👁 Show]  │
│  ← Match status: ✓ Match        │
│                                 │
├─────────────────────────────────┤
│ STEP 2 OF 3: MINECRAFT INFO     │
├─────────────────────────────────┤
│                                 │
│  Minecraft Username *           │
│  [Player_Name_____]             │
│  ← Validation: Alphanumeric,    │
│     max 16 chars, _ allowed     │
│  ← Availability: Not registered │
│                                 │
├─────────────────────────────────┤
│ STEP 3 OF 3: REVIEW & CONFIRM   │
├─────────────────────────────────┤
│                                 │
│  Email:          player@... ✓   │
│  Minecraft Name: PlayerName ✓   │
│  Password:       ••••••••   ✓   │
│                                 │
│  [← Back]  [Register →]         │
│                                 │
└─────────────────────────────────┘
```

### B.2 Form Fields

| Field | Type | Validation | Required | Max Length | Notes |
|-------|------|-----------|----------|-----------|-------|
| **Email** | Email | Format check, duplicate check | Yes | 254 | Case-insensitive; unique |
| **Password** | Password | 8-128 chars, weak password blacklist | Yes | 128 | Hash on backend; never log plaintext |
| **Confirm Password** | Password | Must match Password | Yes | 128 | Real-time comparison |
| **Minecraft Username** | Text | Alphanumeric + `_`, 3-16 chars, unique, valid MC format | Yes | 16 | Case-sensitive; check against existing players |

### B.3 Real-Time Validation

#### Email Field
- **On blur**: Validate format (RFC 5322 simplified)
- **Debounced (300ms)**: Check if email is already registered (hit `/api/users/check-duplicate`)
- **Show indicator**: ✓ Available | ✗ Already in use | ⚠️ Invalid format

#### Password Field
- **On change (debounced 100ms)**:
  - Calculate strength: weak (0-2), fair (3), good (4), strong (5)
  - Factors: length, mixed case, numbers, symbols, common patterns
  - Check against weak password blacklist (client-side: top 100; server validates all)
  - Show strength meter (visual bar)
- **Rules displayed**:
  - ✓ At least 8 characters
  - ✓ No forced complexity (but encouraged)
  - ⚠️ Avoid common passwords (1234567, password, qwerty, etc.)

#### Confirm Password Field
- **On change**: Compare to Password field
- **Show indicator**: ✓ Match | ✗ No match | (empty if Password empty)

#### Minecraft Username Field
- **On blur**: Validate format (3-16 chars, alphanumeric + underscore)
- **Debounced (500ms)**: Check availability (hit `/api/users/check-duplicate`)
- **Show indicator**: ✓ Available | ✗ Taken | ⚠️ Invalid format
- **Help text**: "Format: A-Z, a-z, 0-9, underscore, 3-16 characters"

### B.4 Submit Button State Management

| State | Button Appearance | Enabled? |
|-------|---|---|
| **All fields valid** | Primary color, cursor pointer | ✓ Yes |
| **Any field invalid** | Grayed out, cursor not-allowed | ✗ No |
| **Submitting** | Grayed out + spinner, text: "Creating account..." | ✗ No |
| **Success** | Green checkmark, text: "Account Created!" | ✗ No (auto-redirect after 2s) |
| **Error** | Red exclamation, text: "Try Again" | ✓ Yes (allow retry) |

---

## Part C: Login Form Specification

### C.1 Login Page Layout

```
┌─────────────────────────────────┐
│                                 │
│  Knights & Kings                │
│  Sign In                        │
│                                 │
├─────────────────────────────────┤
│                                 │
│  Email *                        │
│  [_________@example.com_____]  │
│                                 │
│  Password *                     │
│  [_______________]  [👁 Show]  │
│                                 │
│  ☐ Remember Me (14 days)        │
│                                 │
│  [Sign In]                      │
│                                 │
│  Don't have an account?         │
│  [Create one →]                 │
│                                 │
│  [Forgot password?]             │
│  (Future feature)               │
│                                 │
└─────────────────────────────────┘
```

### C.2 Form Fields

| Field | Type | Validation | Required | Notes |
|-------|------|-----------|----------|-------|
| **Email** | Email | Format check only (no API call) | Yes | Match must happen on backend |
| **Password** | Password | No frontend validation | Yes | Backend validates hash |
| **Remember Me** | Checkbox | - | No | Default: unchecked; 14-day persistence suggested |

### C.3 "Remember Me" Implementation

**Option A (Suggested): Persistent Session Cookie**

```typescript
// On successful login
if (rememberMe) {
  // Backend sets secure httpOnly cookie with 14-day expiry
  localStorage.setItem('session-expiry', (now + 14d).toISOString());
  localStorage.setItem('user-email', email); // For display only
} else {
  // Session only (cleared on browser close or timeout)
  sessionStorage.setItem('auth-token', jwt);
}
```

**Pros**:
- User doesn't need to log in again for 14 days
- Secure (httpOnly prevents XSS access)
- Standard UX expectation

**Cons**:
- Requires secure cookie handling
- TBD: What happens after 14 days? Auto-refresh or re-login?

---

**Option B: Auto-Login via Stored Credentials (More Risky)**

```typescript
// LESS SECURE: Not recommended unless encrypted
// If user allows, store encrypted email + partial password hash
// Auto-fill and auto-submit on next visit
```

**Recommendation**: Use **Option A (httpOnly cookie + JWT refresh token pattern)**.

### C.4 Auto-Login on Page Load

```typescript
// App.tsx or ProtectedRoute component
useEffect(() => {
  const token = localStorage.getItem('auth-token');
  if (token) {
    // Validate token with backend (could be expired)
    validateToken(token)
      .then(() => setIsLoggedIn(true))
      .catch(() => {
        // Token expired; clear and show login
        localStorage.clear();
        navigate('/login');
      });
  }
}, []);
```

---

## Part D: Post-Registration Success Page

### D.1 Layout & Content

```
┌─────────────────────────────────┐
│                                 │
│  ✓ Account Created!             │
│                                 │
│  Welcome, player@example.com    │
│                                 │
├─────────────────────────────────┤
│                                 │
│  Your Link Code:                │
│                                 │
│  ┌─────────────────┐            │
│  │  ABC-12XYZ      │            │
│  │ [Copy to Clipboard] │        │
│  └─────────────────┘            │
│                                 │
│  Next Steps:                    │
│  1. Launch Minecraft            │
│  2. Join server: knk.example.com│
│  3. Use: /account link ABC12XYZ │
│  4. Done! Your accounts linked  │
│                                 │
├─────────────────────────────────┤
│                                 │
│  [Go to Dashboard]              │
│  [Sign In]                      │
│                                 │
└─────────────────────────────────┘
```

### D.2 Auto-Redirect Option

**Suggested**: After 3-5 seconds, auto-redirect to login page (so user can log in immediately).

```typescript
useEffect(() => {
  const timer = setTimeout(() => {
    navigate('/login');
  }, 3000);
  return () => clearTimeout(timer);
}, []);
```

---

## Part E: API Integration & Data Flow

### E.1 Registration Request/Response

**Frontend Submits** (POST `/api/users`):
```typescript
{
  username: "PlayerName",
  email: "player@example.com",
  password: "SecurePassword123",
  passwordConfirmation: "SecurePassword123",
  // uuid: null (set when Minecraft join occurs)
}
```

**Backend Response (201 Created)**:
```typescript
{
  user: {
    id: 1,
    username: "PlayerName",
    email: "player@example.com",
    uuid: null,
    coins: 0,
    gems: 0,
    experiencePoints: 0,
    emailVerified: false,
    accountCreatedVia: "WebApp",
    createdAt: "2026-01-16T12:00:00Z"
  },
  linkCode: {
    code: "ABC12XYZ",
    expiresAt: "2026-01-16T12:20:00Z"
  }
}
```

**Backend Error (409 Conflict)**:
```typescript
{
  error: "ValidationFailed",
  message: "Email already in use",
  code: "DuplicateEmail"
}
```

### E.2 Login Request/Response

**Frontend Submits** (POST `/api/auth/login`):
```typescript
{
  email: "player@example.com",
  password: "SecurePassword123",
  rememberMe: true
}
```

**Backend Response (200 OK)**:
```typescript
{
  token: "eyJhbGciOiJIUzI1NiIs...",
  user: {
    id: 1,
    username: "PlayerName",
    email: "player@example.com",
    uuid: "abc-123-def-456",
    coins: 250,
    gems: 50,
    experiencePoints: 1200,
    emailVerified: false,
    accountCreatedVia: "WebApp"
  },
  expiresIn: 3600 // seconds
}
```

**Backend Response (401 Unauthorized)**:
```typescript
{
  error: "InvalidCredentials",
  message: "Email or password is incorrect"
}
```

### E.3 Generate Link Code Request/Response

**Frontend Submits** (POST `/api/users/generate-link-code`):
```typescript
{
  userId: 1 // Current user
}
```

**Backend Response (200 OK)**:
```typescript
{
  code: "XYZ98ABC",
  expiresAt: "2026-01-16T14:35:00Z"
}
```

---

## Part F: TypeScript DTOs & Types

### F.1 Frontend Types (src/types/auth.ts)

```typescript
export interface RegisterFormData {
  email: string;
  password: string;
  passwordConfirmation: string;
  username: string;
}

export interface LoginFormData {
  email: string;
  password: string;
  rememberMe: boolean;
}

export interface User {
  id: number;
  username: string;
  email: string;
  uuid?: string | null;
  coins: number;
  gems: number;
  experiencePoints: number;
  emailVerified: boolean;
  accountCreatedVia: 'WebApp' | 'MinecraftServer';
  createdAt: string;
}

export interface AuthResponse {
  token: string;
  user: User;
  expiresIn: number;
}

export interface LinkCode {
  code: string;
  expiresAt: string;
}

export interface RegisterResponse {
  user: User;
  linkCode: LinkCode;
}

export interface FieldError {
  field: string;
  message: string;
  code?: string;
}

export interface ValidationError {
  error: string;
  message: string;
  code?: string;
  fields?: FieldError[];
}
```

---

## Part G: Validation Rules & Error Handling

### G.1 Frontend Validation Rules

#### Email
- **Format**: RFC 5322 simplified regex or validator library
- **Pattern**: `/^[^\s@]+@[^\s@]+\.[^\s@]+$/`
- **Max length**: 254 characters
- **Error messages**:
  - "Please enter a valid email address"
  - "Email already registered"

#### Password
- **Min length**: 8 characters
- **Max length**: 128 characters
- **Rules** (shown to user):
  - ✓ At least 8 characters
  - (Optional) Mix of upper, lower, numbers, symbols
- **Weak password detection** (client-side):
  - Top 100 common passwords (hardcoded)
  - Pattern detection: consecutive digits (123456), keyboard patterns (qwerty)
  - If detected: Show "This password is too common"
- **Error messages**:
  - "Password must be at least 8 characters"
  - "Password must not exceed 128 characters"
  - "This password is too common"
  - "Passwords do not match"

#### Username (Minecraft)
- **Min length**: 3 characters
- **Max length**: 16 characters
- **Allowed characters**: A-Z, a-z, 0-9, underscore (_)
- **Pattern**: `/^[a-zA-Z0-9_]{3,16}$/`
- **Error messages**:
  - "Username must be 3-16 characters"
  - "Username can only contain letters, numbers, and underscores"
  - "Username already taken"

### G.2 Error Message Strategy

**Approach**: Specific, actionable error messages (not generic "error occurred")

```typescript
const errorMessages: Record<string, string> = {
  'DuplicateEmail': 'Email already registered. Log in or use a different email.',
  'DuplicateUsername': 'Minecraft username already taken. Try a variation.',
  'InvalidPassword': 'Password is too common. Choose something stronger.',
  'PasswordMismatch': 'Passwords do not match.',
  'InvalidEmail': 'Please enter a valid email address.',
  'InvalidUsername': 'Minecraft username must be 3-16 alphanumeric characters.',
  'LinkCodeExpired': 'Link code expired. Generate a new one.',
  'InvalidCredentials': 'Email or password is incorrect.',
  'NetworkError': 'Network error. Please try again.',
  'ServerError': 'Server error. Please try again later.'
};
```

---

## Part H: Accessibility (A11y) Requirements

### H.1 WCAG 2.1 Level AA Compliance

- [ ] **Labels**: All form inputs have associated `<label>` elements
- [ ] **Error association**: Error messages linked to form fields via `aria-describedby`
- [ ] **Focus management**: Focus moved to first invalid field on submit
- [ ] **Keyboard navigation**: Tab order correct; Enter submits form
- [ ] **Color contrast**: Text meets 4.5:1 contrast ratio (WCAG AA)
- [ ] **Screen reader support**: Form fields announced with type, value, error state

### H.2 Example Accessible Form Input

```tsx
<div>
  <label htmlFor="email">Email Address *</label>
  <input
    id="email"
    type="email"
    aria-required="true"
    aria-describedby={error ? "email-error" : undefined}
    {...register('email')}
  />
  {error && (
    <span id="email-error" role="alert" className="error">
      {error}
    </span>
  )}
</div>
```

### H.3 Screen Reader Announcements

- Form submission errors announced via `role="alert"` container
- Success messages announced via `role="status"`
- Loading states communicated ("Creating account, please wait...")

---

## Part I: Security Considerations

### I.1 Frontend Security Practices

- [ ] **HTTPS Only**: Never transmit credentials over HTTP
- [ ] **Password never logged**: Never log or display plaintext passwords
- [ ] **Token storage**: JWT stored in httpOnly cookie (prefer over localStorage for XSS safety)
- [ ] **CSRF Protection**: Include CSRF token in state-changing requests (POST, PUT, DELETE)
- [ ] **Rate limiting**: Implement client-side throttling on login attempts (after 3 failures, 1-minute delay)
- [ ] **Input sanitization**: Validate all user inputs; sanitize for display to prevent XSS
- [ ] **Secure password field**: Use `type="password"`, disable autocomplete warnings if needed

### I.2 Example: Rate Limiting

```typescript
const [loginAttempts, setLoginAttempts] = useState(0);
const [isThrottled, setIsThrottled] = useState(false);

const handleLoginSubmit = async (data: LoginFormData) => {
  if (isThrottled) {
    showError('Too many login attempts. Please wait 1 minute.');
    return;
  }

  try {
    await login(data);
    setLoginAttempts(0); // Reset on success
  } catch (error) {
    setLoginAttempts(attempts => attempts + 1);
    if (attempts >= 3) {
      setIsThrottled(true);
      setTimeout(() => setIsThrottled(false), 60000); // 1 minute
    }
  }
};
```

---

## Part J: UI Components & Structure

### J.1 Suggested Component Hierarchy

```
/src
  /pages
    /auth
      ├─ RegisterPage.tsx
      ├─ LoginPage.tsx
      └─ RegisterSuccessPage.tsx
  /components
    /auth
      ├─ RegisterForm.tsx
        ├─ FormStep1.tsx (email, password)
        ├─ FormStep2.tsx (username)
        └─ FormStep3.tsx (review)
      ├─ LoginForm.tsx
      ├─ PasswordStrengthMeter.tsx
      ├─ FieldError.tsx
      └─ FormStepper.tsx
  /hooks
    ├─ useAuth.ts (login/logout logic)
    ├─ useFormValidation.ts (field validation)
    └─ useRememberMe.ts (session persistence)
  /services
    ├─ authService.ts (API calls)
    └─ tokenService.ts (JWT management)
  /types
    └─ auth.ts (DTOs & interfaces)
```

### J.2 Example: RegisterForm Component

```tsx
export const RegisterForm: React.FC = () => {
  const [step, setStep] = useState(1);
  const [formData, setFormData] = useState<RegisterFormData>({
    email: '',
    password: '',
    passwordConfirmation: '',
    username: '',
  });
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [isLoading, setIsLoading] = useState(false);

  const validateStep = (stepNum: number): boolean => {
    const newErrors: Record<string, string> = {};

    if (stepNum === 1) {
      if (!formData.email) newErrors.email = 'Email is required';
      else if (!isValidEmail(formData.email)) newErrors.email = 'Invalid email';
      
      if (!formData.password) newErrors.password = 'Password is required';
      else if (formData.password.length < 8) newErrors.password = 'Min 8 characters';
      
      if (formData.password !== formData.passwordConfirmation)
        newErrors.passwordConfirmation = 'Passwords do not match';
    }

    if (stepNum === 2) {
      if (!formData.username) newErrors.username = 'Username is required';
      else if (!isValidUsername(formData.username))
        newErrors.username = 'Invalid format (3-16 alphanumeric)';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleNextStep = () => {
    if (validateStep(step)) setStep(step + 1);
  };

  const handleSubmit = async () => {
    if (!validateStep(3)) return;

    setIsLoading(true);
    try {
      const response = await authService.register(formData);
      // Show success page with link code
      navigate('/register-success', { state: { linkCode: response.linkCode } });
    } catch (error) {
      setErrors({ submit: error.message });
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="register-form">
      <FormStepper currentStep={step} totalSteps={3} />

      {step === 1 && (
        <FormStep1
          formData={formData}
          errors={errors}
          onChange={(field, value) => setFormData({ ...formData, [field]: value })}
        />
      )}
      {step === 2 && (
        <FormStep2
          formData={formData}
          errors={errors}
          onChange={(field, value) => setFormData({ ...formData, [field]: value })}
        />
      )}
      {step === 3 && <FormStep3 formData={formData} />}

      <div className="form-actions">
        {step > 1 && <button onClick={() => setStep(step - 1)}>Back</button>}
        {step < 3 && <button onClick={handleNextStep}>Next</button>}
        {step === 3 && (
          <button onClick={handleSubmit} disabled={isLoading}>
            {isLoading ? 'Creating Account...' : 'Register'}
          </button>
        )}
      </div>
    </div>
  );
};
```

---

## Part K: Testing Strategy

### K.1 Unit Tests

- [ ] Password strength calculation
- [ ] Email format validation
- [ ] Username format validation
- [ ] Form field validation logic
- [ ] Token parsing & expiration check
- [ ] Error message mapping

### K.2 Integration Tests

- [ ] Registration flow (all 3 steps)
- [ ] Login flow
- [ ] "Remember Me" persistence
- [ ] Auto-login on page load
- [ ] Link code display & copy-to-clipboard
- [ ] Error scenarios (duplicate email, weak password, etc.)

### K.3 E2E Tests (Cypress)

```typescript
describe('User Registration & Login', () => {
  it('should register a new user', () => {
    cy.visit('/register');
    cy.get('[data-testid="email"]').type('newuser@example.com');
    cy.get('[data-testid="password"]').type('SecurePass123!');
    cy.get('[data-testid="password-confirm"]').type('SecurePass123!');
    cy.get('[data-testid="next"]').click();
    cy.get('[data-testid="username"]').type('NewPlayer');
    cy.get('[data-testid="next"]').click();
    cy.get('[data-testid="register"]').click();
    cy.contains('Account Created').should('be.visible');
    cy.contains(/[A-Z0-9]{3}-[A-Z0-9]{5}/).should('be.visible'); // Link code
  });

  it('should reject weak password', () => {
    cy.visit('/register');
    cy.get('[data-testid="password"]').type('123456');
    cy.contains('too common').should('be.visible');
    cy.get('[data-testid="next"]').should('be.disabled');
  });

  it('should login user', () => {
    cy.visit('/login');
    cy.get('[data-testid="email"]').type('user@example.com');
    cy.get('[data-testid="password"]').type('SecurePass123!');
    cy.get('[data-testid="sign-in"]').click();
    cy.url().should('include', '/dashboard');
  });

  it('should remember user (14 days)', () => {
    cy.visit('/login');
    cy.get('[data-testid="email"]').type('user@example.com');
    cy.get('[data-testid="password"]').type('SecurePass123!');
    cy.get('[data-testid="remember-me"]').click();
    cy.get('[data-testid="sign-in"]').click();

    cy.clearCookies(); // Simulate browser close
    cy.visit('/dashboard');
    cy.url().should('include', '/dashboard'); // Should auto-login
  });
});
```

---

## Part L: Implementation Phases

### Phase 1: Core Registration (Week 1)

- [ ] Create RegisterPage & RegisterForm components
- [ ] Implement 3-step form with validation
- [ ] Add API integration (POST `/api/users`)
- [ ] Show RegisterSuccessPage with link code
- [ ] Add form styling & basic error handling

**Estimated Effort**: 16-20 hours

---

### Phase 2: Core Login (Week 2)

- [ ] Create LoginPage & LoginForm components
- [ ] Implement login validation
- [ ] Add JWT token management (storage, parsing, refresh)
- [ ] Add "Remember Me" checkbox + 14-day persistence
- [ ] Add auto-login on page load

**Estimated Effort**: 12-16 hours

---

### Phase 3: Polish & Accessibility (Week 3)

- [ ] Add real-time field validation (email, password, username)
- [ ] Add password strength meter
- [ ] Add copy-to-clipboard button for link code
- [ ] Implement WCAG 2.1 AA compliance
- [ ] Add rate limiting for login attempts
- [ ] Write E2E tests

**Estimated Effort**: 12-16 hours

---

### Phase 4: Advanced Features (Future)

- [ ] Password reset / "Forgot Password" flow
- [ ] Email verification (optional)
- [ ] Account linking dashboard (show Minecraft linking status)
- [ ] Social login (GitHub, Discord? TBD)
- [ ] Multi-factor authentication (TBD)

**Estimated Effort**: TBD per feature

---

## Part M: Design & UX Recommendations

### M.1 Design System Requirements

- **Primary color**: (Use existing KnK brand color)
- **Error color**: Red (#dc2626 or similar)
- **Success color**: Green (#16a34a or similar)
- **Input focus state**: Blue border + shadow
- **Loading state**: Spinner + disabled button
- **Font**: System font stack or project default

### M.2 Mobile Responsiveness

- [ ] Form width: Max 400px on mobile, 500px on desktop
- [ ] Buttons: Full-width on mobile, auto on desktop
- [ ] Field spacing: 16px on mobile, 24px on desktop
- [ ] Font sizes: 16px min on input fields (prevents iOS zoom)

### M.3 Dark Mode (Optional)

- If project uses dark mode, ensure:
  - Text contrast meets WCAG AA (4.5:1)
  - Input borders visible on dark background
  - Error messages readable

---

## Part N: Questions for Clarification

**Please confirm or adjust the following**:

1. **Remember Me Duration**: Should it be 14 days? 30 days?
2. **Password Reset**: Should we implement "Forgot Password" flow in Phase 2 or later?
3. **Email Verification**: Should users verify email before account creation, or optional?
4. **Multi-Step Form**: Preferred to break registration into steps, or single-page?
5. **Auto-Login**: Should the app silently auto-login if valid token exists, or show loading?
6. **Password Complexity**: Should we recommend (but not require) uppercase/numbers/symbols?
7. **Social Login**: Should we plan for OAuth (GitHub, Discord) integration?
8. **Rate Limiting**: What should be the login attempt threshold? (Currently suggested 3 attempts → 1-minute delay)
9. **UI Framework**: Should we use Material-UI, shadcn/ui, or custom components?
10. **Form Validation Library**: React Hook Form + Zod? Or alternatives?

---

## Appendix A: Sample Password Blacklist (Client-Side)

```typescript
// Top 50 weak passwords (show warning for these)
const weakPasswords = new Set([
  '123456', '123456789', '12345678', 'password', 'qwerty',
  '111111', '123123', '1234567', 'dragon', 'baseball',
  'abc123', 'football', 'monkey', 'letmein', 'shadow',
  'master', '666666', 'qwertyuiop', '123321', 'mustang',
  '1234567890', 'michael', '654321', 'superman', '1qaz2wsx',
  '7777777', '121212', '000000', 'qazwsx', 'admin',
  'admin123', 'root', 'pass', 'test', 'guest',
  'info', 'adm', 'mysql', 'user', 'oracle',
  'ftp', 'pi', 'puppet', 'ansible', 'vagrant'
]);

export const isWeakPassword = (password: string): boolean => {
  return weakPasswords.has(password.toLowerCase());
};
```

---

## Appendix B: Suggested Folder Structure & Files

```
src/
├── pages/
│   └── auth/
│       ├── RegisterPage.tsx (main container)
│       ├── LoginPage.tsx
│       └── RegisterSuccessPage.tsx
├── components/
│   └── auth/
│       ├── RegisterForm.tsx
│       ├── FormStep1.tsx (email, password)
│       ├── FormStep2.tsx (username)
│       ├── FormStep3.tsx (review)
│       ├── FormStepper.tsx (visual indicator)
│       ├── LoginForm.tsx
│       ├── PasswordStrengthMeter.tsx
│       ├── FieldError.tsx
│       └── LinkCodeDisplay.tsx
├── hooks/
│   ├── useAuth.ts (login, logout, getCurrentUser)
│   ├── useFormValidation.ts (validation logic)
│   └── useRememberMe.ts (session persistence)
├── services/
│   ├── authService.ts (API: register, login, logout, validateToken)
│   └── tokenService.ts (JWT parsing, expiry check, storage)
├── types/
│   └── auth.ts (DTO interfaces, User, AuthResponse, etc.)
├── utils/
│   ├── validation.ts (email, password, username validators)
│   └── constants.ts (error messages, weak password list)
└── styles/
    ├── auth.module.css (or Tailwind classes)
    └── responsive.css
```

---

## Next Steps

1. **Review & Confirm**: Please review this document and provide feedback on:
   - User flows (any missing scenarios?)
   - Form layout & fields (correct?)
   - "Remember Me" approach (secure enough?)
   - Error handling strategy (aligned with backend errors?)

2. **Design Mockups**: Create Figma/design mockups for:
   - Registration form (3-step view)
   - Login form
   - Success page

3. **Backend Coordination**: Align with backend team on:
   - JWT token format & refresh strategy
   - Error response format (already matched in spec)
   - Rate limiting on backend
   - Token expiration times

4. **Start Implementation**: After approval, create feature branch and implement Phase 1.

---

**Document Version**: 1.0  
**Last Updated**: January 16, 2026  
**Author**: AI Assistant  
**Status**: **AWAITING FEEDBACK**
