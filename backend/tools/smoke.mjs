// Real loopback-only backend smoke test. Tokens never appear in output.
import assert from "node:assert/strict";
const base = process.env.PASSPORT_TEST_BACKEND ?? "http://127.0.0.1:3210";
if (!/^http:\/\/(127\.0\.0\.1|localhost):\d+$/.test(base)) throw new Error("Smoke test only permits loopback deployments");
async function call(type, path, args, token = "") {
  const response = await fetch(`${base}/api/${type}`, {
    method: "POST", headers: {"Content-Type": "application/json", ...(token ? {Authorization: `Bearer ${token}`} : {})},
    body: JSON.stringify({path, args, format: "json"}),
  });
  const result = await response.json();
  if (result.status !== "success") throw new Error(`Backend call failed: ${path}: ${String(result.errorMessage ?? result.message ?? response.status).replace(/eyJ[A-Za-z0-9._-]+/g, "[token]")}`);
  return result.value;
}
const {tokens} = await call("action", "devAuth:signIn", {provider: "anonymous"});
assert.ok(tokens.token && tokens.refreshToken);
const daily = await call("query", "runs:daily", {difficulty: "easy"});
const run = await call("mutation", "runs:begin", {mode: "daily", difficulty: "easy"}, tokens.token);
assert.equal(run.seed, daily.seed);
assert.deepEqual(run.route, daily.route);
const submitted = await call("mutation", "runs:submit", {runId: run.runId, events: [], endedAtMs: 0}, tokens.token);
assert.equal(submitted.score, 0);
const board = await call("query", "runs:leaderboard", {mode: "daily", difficulty: "easy"});
assert.ok(board.some((entry) => entry.displayName.startsWith("Explorer") && entry.score === 0));
const profile = await call("mutation", "players:syncPassport", {homeCountry: "FR", discoveries: ["FR"]}, tokens.token);
assert.deepEqual(profile.discoveries, ["FR"]);
const refreshed = await call("action", "devAuth:signIn", {refreshToken: tokens.refreshToken});
assert.ok(refreshed.tokens.token);
await call("action", "auth:signOut", {}, refreshed.tokens.token);
console.log("PASS: real local anonymous sign-in, manifest, submission, board, passport sync, refresh and sign-out");
