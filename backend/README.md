# Passport Run local competition backend

This Convex backend was exercised against a real **local** Convex instance. No hosted deployment is provisioned. The shipped Godot project leaves online play disabled until a backend URL is configured.

## Local development

```sh
cd backend
npm ci
CONVEX_AGENT_MODE=anonymous npx convex init
node tools/local_auth_keys.mjs /private/tmp/passport-local-auth.env
CONVEX_AGENT_MODE=anonymous npx convex env set --force --from-file /private/tmp/passport-local-auth.env
CONVEX_AGENT_MODE=anonymous npx convex dev --env-file .env.local
```

Use a separate terminal for checks:

```sh
cd backend
npm run check
npm test
node tools/smoke.mjs
```

The smoke script accepts only loopback URLs. `.env.local`, `.convex/`, key files, and dependencies are excluded from version control. Keep the private temporary key file private; delete it after configuring local environment variables. A key rotation invalidates existing access tokens.

In Godot's Project Settings add the string `network/backend_url` = `http://127.0.0.1:3210` for desktop testing. Remove it before exporting an offline app. A phone's loopback addresses the phone, not the Mac. A hosted deployment must use HTTPS; arbitrary external HTTP URLs are rejected.

With the server running, from the project root:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_online.gd
```

`tests/export_contract.gd` regenerates the compatibility fixtures used by the backend tests. Treat generator and balance version 1 as immutable.

## Trust and persistence

Convex Auth owns anonymous identities and sessions. Mutation authorization checks the live session record, expiry and user ownership. Refresh credentials are stored in a separate local Godot file; access tokens stay in memory. Anonymous identity can be lost if local credentials are removed; account linking/recovery is unfinished.

Server manifests choose Daily date/seed/route and Infinite seed. Retries reference an owned previous run and retain its manifest across midnight. Submissions reconstruct safe lanes and scores using exact integer arithmetic, enforce event order and minimum timing, reject duplicate/foreign/expired submissions, and atomically update personal bests. Boards are separated by mode, difficulty, date, generator and balance version. Public results expose generated Explorer aliases rather than authentication records.

A client replay proves consistency with game rules; it cannot prove that a human remembered the path. Bot resistance and release abuse controls still need work. Replays are bounded to 4,096 choices; longer runs remain playable locally but are not ranked. Ending a run via the menu does not submit a ranked score.

Passport discoveries merge as a union; home country uses last writer. Local history/preferences and all Kids play remain local. Passport synchronization never grants leaderboard points.

Local HTTP cannot serve hosted OIDC discovery, so local auth verifies inline public keys. `devAuth:signIn` delegates actual Convex Auth session creation and re-signs its claims with the required key ID; it rejects non-loopback deployments. Hosted clients use standard `auth:signIn` and OIDC. Verify hosted auth and refresh separately before release.

## Release work

Provision a hosted project and keys, configure its site URL, verify native HTTPS/auth/refresh and data retention, add account recovery and abuse limits, and review public competition with real players. Ads, purchases, hosted challenge links, native sharing and remote analytics are not implemented by this backend. Test users and scores are local development evidence only.
