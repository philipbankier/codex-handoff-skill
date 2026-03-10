# Example Plan: Add User Authentication

This is an example of the plan format that codex-handoff expects. Plans can live in `docs/plans/`, `.claude/plans/`, or be provided inline.

---

## Goal

Add JWT-based authentication to the Express API.

## Items

### 1. Install dependencies
- `npm install jsonwebtoken bcryptjs`
- Add `@types/jsonwebtoken` and `@types/bcryptjs` as dev dependencies

### 2. Create auth middleware — `src/middleware/auth.ts`
- Extract JWT from `Authorization: Bearer <token>` header
- Verify token using `JWT_SECRET` from environment
- Attach decoded user to `req.user`
- Return 401 if token is missing or invalid

### 3. Create auth routes — `src/routes/auth.ts`
- `POST /auth/register` — hash password with bcrypt, create user, return JWT
- `POST /auth/login` — verify credentials, return JWT
- Both endpoints validate input and return appropriate error messages

### 4. Protect existing routes
- Add auth middleware to `GET /api/projects` and `POST /api/projects`
- Add auth middleware to `GET /api/tasks` and `POST /api/tasks`

### 5. Add tests — `src/__tests__/auth.test.ts`
- Test registration with valid and invalid input
- Test login with correct and incorrect credentials
- Test protected routes with and without valid token

### 6. Update environment
- Add `JWT_SECRET` to `.env.example`
- Add `JWT_EXPIRY=7d` to `.env.example`

## Verification
- `npm test` passes
- `npm run build` succeeds
- Manual test: register -> login -> access protected route with token
