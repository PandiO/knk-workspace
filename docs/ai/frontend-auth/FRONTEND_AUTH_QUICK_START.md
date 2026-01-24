# Frontend User Account Management - Quick Start Guide

**For Developers**: Quick reference for implementing user auth in knk-web-app  
**Status**: Ready  
**Created**: January 16, 2026

---

## TL;DR - What You Need to Know

### Key Decisions (Already Made)
- ✅ **Multi-step registration** (3 steps: email/password → username → review)
- ✅ **Remember Me: 30 days** (industry standard for MMORPGs)
- ✅ **httpOnly cookies** for token storage (secure)
- ✅ **Password strength meter** (8-128 chars, no forced complexity, weak password blacklist)
- ✅ **Auto-login on page load** (silent if valid token exists)
- ✅ **Email verification after 3 failed logins** (Phase 4 - future)
- ✅ **Landing page always visible** (with slideshow, CTA buttons)
- ✅ **Navigation hidden until login** (protected routes + ProtectedRoute wrapper)

---

## Project Structure Overview

```
knk-web-app/src/
├── apiClients/
│   ├── authClient.ts (NEW - API calls for auth)
│   └── ...existing clients...
│
├── components/
│   ├── auth/ (NEW FOLDER)
│   │   ├── RegisterForm.tsx (3-step form container)
│   │   ├── FormStep1.tsx (email/password)
│   │   ├── FormStep2.tsx (username)
│   │   ├── FormStep3.tsx (review)
│   │   ├── LoginForm.tsx
│   │   ├── PasswordStrengthMeter.tsx
│   │   ├── FormStepper.tsx
│   │   ├── LinkCodeDisplay.tsx
│   │   └── index.ts (barrel export)
│   ├── ProtectedRoute.tsx (NEW - route protection)
│   ├── LoadingScreen.tsx (NEW - loading spinner)
│   ├── Navigation.tsx (UPDATED - add logout, conditional render)
│   └── ...existing components...
│
├── pages/
│   ├── auth/ (NEW FOLDER)
│   │   ├── RegisterPage.tsx
│   │   ├── LoginPage.tsx
│   │   ├── RegisterSuccessPage.tsx
│   │   └── index.ts
│   ├── LandingPage.tsx (UPDATED - add CTA buttons)
│   └── ...existing pages...
│
├── hooks/ (NEW FOLDER)
│   ├── useAuth.ts (auth state management)
│   ├── useAutoLogin.ts (auto-login on mount)
│   └── ...future hooks...
│
├── services/ (UPDATED)
│   ├── authService.ts (NEW - auth business logic)
│   ├── tokenService.ts (NEW - JWT/session handling)
│   ├── serviceCall.ts (existing - HTTP layer)
│   └── ...existing services...
│
├── types/
│   ├── dtos/
│   │   ├── auth/ (NEW FOLDER)
│   │   │   ├── UserDtos.ts
│   │   │   └── AuthDtos.ts
│   │   └── ...existing dtos...
│   └── ...existing types...
│
└── utils/
    ├── authConstants.ts (NEW - constants, error messages)
    ├── passwordValidator.ts (NEW - strength calculation)
    └── ...existing utils...
```

---

## Implementation Phases & Timeline

| Phase | Focus | Files | Days | 
|-------|-------|-------|------|
| **1** | API Client & Services | authClient.ts, authService.ts, DTOs | 1.5-2 |
| **2** | Registration Form | RegisterPage, 3-step form components | 2-2.5 |
| **3** | Login Form | LoginPage, LoginForm, auto-login | 1.5-2 |
| **4** | Success & Link Code | RegisterSuccessPage, LinkCodeDisplay | 0.5-1 |
| **5** | Polish & A11y | WCAG compliance, keyboard nav, tests | 1-1.5 |
| **6** | Testing & Docs | E2E tests, documentation | 2-2.5 |
| **TOTAL** | | **68-90 hours** | **8.5-11.5 days** |

---

## API Endpoints (Backend Already Complete)

### Authentication Endpoints

```
POST /api/users
  Request:  { username, email, password, passwordConfirmation }
  Response: 201 Created { user, linkCode }
  Errors:   409 Conflict (duplicate email/username)
            400 Bad Request (validation)

POST /api/auth/login
  Request:  { email, password, rememberMe }
  Response: 200 OK { token, user, expiresIn }
  Errors:   401 Unauthorized (wrong credentials)

POST /api/auth/validate-token
  Request:  { token }
  Response: 200 OK { valid: true }
  Errors:   401 Unauthorized (expired/invalid)

POST /api/users/generate-link-code
  Request:  { userId }
  Response: 200 OK { code, expiresAt }

POST /api/users/check-duplicate
  Request:  { email?, username?, uuid? }
  Response: 200 OK { hasDuplicate, conflictingUser? }
```

---

## Code Patterns to Follow

### 1. API Client Pattern
```typescript
// Follow existing pattern (e.g., townClient.ts)
export class AuthClient {
  async register(data: RegisterRequestDto): Promise<RegisterResponseDto> {
    const serviceCall = new ServiceCall();
    return await serviceCall.invokeApiService({
      controller: 'users',
      operation: 'register',
      httpMethod: HttpMethod.Post,
      requestData: data,
    });
  }
}

export const authClient = new AuthClient();
```

### 2. Service Layer Pattern
```typescript
// Wrap client with business logic
export class AuthService {
  async login(email: string, password: string, rememberMe: boolean) {
    const response = await authClient.login({ email, password, rememberMe });
    this.storeToken(response.token, rememberMe);
    return response.user;
  }
}

export const authService = new AuthService();
```

### 3. Hook Pattern
```typescript
// Manage component state
export function useAuth() {
  const [user, setUser] = useState(null);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const login = useCallback(async (email, password, rememberMe) => {
    setIsLoading(true);
    try {
      const user = await authService.login(email, password, rememberMe);
      setUser(user);
    } catch (err) {
      setError(err.message);
    } finally {
      setIsLoading(false);
    }
  }, []);

  return { user, isLoading, error, login };
}
```

### 4. Component Pattern
```typescript
// Use existing FeedbackModal, ErrorView, Tailwind classes
export const RegisterForm: React.FC = () => {
  const [step, setStep] = useState(1);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const { register, isLoading } = useAuth();

  return (
    <div className="max-w-md mx-auto bg-white rounded-lg shadow p-6">
      <FormStepper currentStep={step} totalSteps={3} />
      
      {step === 1 && <FormStep1 />}
      {step === 2 && <FormStep2 />}
      {step === 3 && <FormStep3 />}

      {errors.submit && <ErrorView content={errors.submit} />}
      
      <button onClick={handleSubmit} disabled={isLoading}>
        {isLoading ? 'Creating...' : 'Continue'}
      </button>
    </div>
  );
};
```

---

## Key Validation Rules

### Password
- **Min 8 chars, Max 128 chars**
- **No forced complexity** (but can include uppercase, numbers, symbols)
- **Blacklist**: Top 1000 compromised passwords
- **Pattern detection**: keyboard patterns (qwerty, asdf), sequential (123abc)

### Email
- **Format check**: RFC 5322 simplified regex
- **Availability check**: API call (debounced 300ms)

### Username (Minecraft)
- **3-16 alphanumeric + underscore**
- **Availability check**: API call (debounced 500ms)

### Strength Meter Levels
```
0: Very Weak  (red)        #dc2626
1: Weak       (orange)     #ea580c
2: Fair       (yellow)     #eab308
3: Good       (light-green) #84cc16
4: Strong     (green)      #22c55e
5: Very Strong (dark-green) #16a34a
```

---

## Error Handling

### Map Backend Errors to User Messages

```typescript
const errorMap: Record<string, string> = {
  'DuplicateEmail': 'Email already registered. Log in or use a different email.',
  'DuplicateUsername': 'Username already taken. Try a variation.',
  'InvalidPassword': 'Password too common. Choose something stronger.',
  'PasswordMismatch': 'Passwords do not match.',
  'InvalidCredentials': 'Email or password is incorrect.',
  'LinkCodeExpired': 'Link code expired (valid 20 minutes).',
  'NetworkError': 'Network error. Try again.',
  'ServerError': 'Server error. Try again later.',
};
```

### Display Errors
```typescript
// Field-level errors (use ErrorView)
<ErrorView content={errors.email} />

// Form-level success/errors (use FeedbackModal)
<FeedbackModal
  open={showFeedback}
  title="Success"
  message="Account created!"
  status="success"
/>
```

---

## Session Management

### localStorage Keys
```typescript
'auth-token'        // JWT token (always set)
'user'              // User object (JSON stringified)
'session-expiry'    // Expiry timestamp (if remember me)
```

### Token Lifecycle
```
User Registration/Login
  ↓
Backend returns JWT token
  ↓
Frontend stores in localStorage + httpOnly cookie
  ↓
If "Remember Me": localStorage.session-expiry = now + 30 days
  ↓
Auto-login: Check localStorage for token → validate with backend
  ↓
If valid: Silently login → redirect to dashboard
If invalid/expired: Clear storage → show login page
```

---

## Testing Checklist

### Unit Tests
- [ ] Password strength calculation
- [ ] Email format validation
- [ ] Username format validation
- [ ] Error message mapping

### Integration Tests
- [ ] Register → Success → Link code displayed
- [ ] Register duplicate email → Error shown
- [ ] Login valid → Token stored → Redirect
- [ ] Login invalid → Error shown
- [ ] Auto-login with valid token → Redirect
- [ ] Auto-login with expired token → Redirect to login

### E2E Tests (Cypress)
```typescript
describe('Auth Flow', () => {
  it('registers user', () => {
    cy.visit('/');
    cy.contains('Create Account').click();
    // ...fill form...
    cy.contains('Account Created').should('be.visible');
  });

  it('logs in user', () => {
    cy.visit('/auth/login');
    cy.get('[data-testid="email"]').type('test@example.com');
    cy.get('[data-testid="password"]').type('password');
    cy.get('[data-testid="sign-in"]').click();
    cy.url().should('include', '/dashboard');
  });
});
```

---

## Common Mistakes to Avoid

❌ **Don't**:
- Store password in localStorage (ever!)
- Use token as string directly without validation
- Skip password hashing on backend (backend does this)
- Ignore 401 responses during API calls (means token expired)
- Use sessionStorage for Remember Me (cleared on close)
- Skip CSRF token for form submissions

✅ **Do**:
- Store JWT in httpOnly cookie (backend sets it)
- Validate token before accessing protected routes
- Handle 401 by logging out + redirecting
- Use localStorage for persistent session data
- Include CSRF token in headers (check backend requirements)
- Test auto-login flow thoroughly
- Add loading states while checking session

---

## Debugging Tips

### Check Session State
```javascript
// In browser console
localStorage.getItem('auth-token')
localStorage.getItem('user')
localStorage.getItem('session-expiry')
document.cookie // Check httpOnly cookie (won't see it, but it exists)
```

### Test Token Validation
```javascript
// Remove/expire token and refresh page
localStorage.removeItem('auth-token');
location.reload(); // Should go to login page
```

### Check API Responses
```javascript
// In network tab (F12 → Network)
// Watch POST /api/auth/login response
// Should include: { token, user, expiresIn }
```

---

## Documentation Files

| Document | Purpose |
|----------|---------|
| [SPEC_USER_ACCOUNT_MANAGEMENT.md](../spec/SPEC_USER_ACCOUNT_MANAGEMENT.md) | Backend spec & requirements |
| [FRONTEND_USER_ACCOUNT_MANAGEMENT_REQUIREMENTS.md](./FRONTEND_USER_ACCOUNT_MANAGEMENT_REQUIREMENTS.md) | Detailed frontend requirements |
| [FRONTEND_USER_ACCOUNT_MANAGEMENT_IMPLEMENTATION_ROADMAP.md](./FRONTEND_USER_ACCOUNT_MANAGEMENT_IMPLEMENTATION_ROADMAP.md) | Step-by-step implementation plan |
| [LANDING_PAGE_NAVIGATION_ARCHITECTURE.md](./LANDING_PAGE_NAVIGATION_ARCHITECTURE.md) | Landing page & routing setup |
| This file | Quick reference & cheat sheet |

---

## Next Steps

1. **Start Phase 1** (Foundation)
   - [ ] Create authClient.ts
   - [ ] Create DTOs (UserDtos.ts, AuthDtos.ts)
   - [ ] Create authService.ts
   - [ ] Create useAuth.ts, useAutoLogin.ts hooks

2. **Update App.tsx**
   - [ ] Add useAutoLogin hook
   - [ ] Add ProtectedRoute wrapper
   - [ ] Update routing structure
   - [ ] Add conditional Navigation

3. **Start Phase 2** (Registration)
   - [ ] Create RegisterPage.tsx
   - [ ] Create 3-step form components
   - [ ] Add PasswordStrengthMeter
   - [ ] Integrate with API

4. **Continue with Phases 3-6**
   - [ ] Login form
   - [ ] Success page
   - [ ] Polish & accessibility
   - [ ] Testing

---

## Questions? Check These Files

- **"How do I structure the API client?"** → Look at `src/apiClients/townClient.ts`
- **"How do I render multi-step forms?"** → Look at `src/components/FormWizard/FormWizard.tsx`
- **"How do I use FeedbackModal?"** → Look at `src/components/FeedbackModal.tsx`
- **"How do I handle errors?"** → Look at `src/components/ErrorView.tsx`
- **"How are types organized?"** → Look at `src/types/dtos/`
- **"What's the HTTP method enum?"** → Look at `src/utils/enums.ts`

---

**Status**: ✅ Ready to Code  
**Last Updated**: January 16, 2026
