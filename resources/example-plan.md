# Example Plan: Add User Authentication

This is an example of the plan format that codex-handoff expects. Plans can live in `docs/plans/`, `.claude/plans/`, or be provided inline.

Plans with `## Phase` headings are automatically executed phase-by-phase. Plans without phase headings are executed in a single pass.

---

## Phase 1: Backend Foundation

### 1.1 Install dependencies
- `npm install jsonwebtoken bcryptjs`
- Add `@types/jsonwebtoken` and `@types/bcryptjs` as dev dependencies

### 1.2 Create auth middleware — `src/middleware/auth.ts`
- Extract JWT from `Authorization: Bearer <token>` header
- Verify token using `JWT_SECRET` from environment
- Attach decoded user to `req.user`
- Return 401 if token is missing or invalid

### 1.3 Create auth routes — `src/routes/auth.ts`
- `POST /auth/register` — hash password with bcrypt, create user, return JWT
- `POST /auth/login` — verify credentials, return JWT
- Both endpoints validate input and return appropriate error messages

### 1.4 Update environment
- Add `JWT_SECRET` to `.env.example`
- Add `JWT_EXPIRY=7d` to `.env.example`

## Phase 2: Frontend Integration

### 2.1 Add login page — `src/pages/login.tsx`
- Email and password form
- Call `POST /auth/login` on submit
- Store JWT in localStorage
- Redirect to dashboard on success

### 2.2 Add auth context — `src/contexts/auth.tsx`
- `AuthProvider` with `user`, `login`, `logout`, `isAuthenticated`
- Auto-check token on mount, redirect to login if expired
- Wrap app in `AuthProvider`

### 2.3 Protect routes
- Add auth middleware to `GET /api/projects` and `POST /api/projects`
- Add auth middleware to `GET /api/tasks` and `POST /api/tasks`
- Frontend: redirect unauthenticated users to login page

## Phase 3: Testing

### 3.1 Backend auth tests — `src/__tests__/auth.test.ts`
- Test registration with valid and invalid input
- Test login with correct and incorrect credentials
- Test protected routes with and without valid token

### 3.2 Frontend auth tests — `src/__tests__/auth-ui.test.tsx`
- Test login form renders and submits
- Test auth context provides user state
- Test redirect behavior for unauthenticated users

### 3.3 E2E test — `src/__tests__/auth.e2e.ts`
- Register → login → access protected route → logout → verify redirect

## Verification
- `npm test` passes
- `npm run build` succeeds
- Manual test: register -> login -> access protected route with token
