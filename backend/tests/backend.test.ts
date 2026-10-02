import { afterEach, expect, test, vi } from "vitest";
import { convexTest } from "convex-test";
import schema from "../convex/schema";
import { api } from "../convex/_generated/api";
import { BALANCE, derivedSeed, laneAt } from "../convex/competition";
const modules = import.meta.glob("../convex/**/*.ts");
afterEach(() => vi.useRealTimers());

async function setup() {
  const t = convexTest(schema, modules);
  const userId = await t.run((ctx) => ctx.db.insert("users", { isAnonymous: true }));
  const sessionId = await t.run((ctx) => ctx.db.insert("authSessions", {userId, expirationTime: Date.now() + 48 * 60 * 60 * 1000}));
  return { t, userId, sessionId, client: t.withIdentity({subject: `${userId}|${sessionId}`}) };
}

test("unauthenticated writes fail", async () => {
  const {t} = await setup();
  await expect(t.mutation(api.runs.begin, {mode: "daily", difficulty: "easy"})).rejects.toThrow("Authentication required");
  await expect(t.mutation(api.players.syncPassport, {homeCountry: "FR", discoveries: []})).rejects.toThrow("Authentication required");
});
test("daily manifest ignores local date and home", async () => {
  vi.useFakeTimers(); vi.setSystemTime(Date.UTC(2026, 9, 2));
  const {t, client} = await setup();
  const manifest = await t.query(api.runs.daily, {difficulty: "easy"});
  const issued = await client.mutation(api.runs.begin, {mode: "daily", difficulty: "easy"});
  expect(issued.date).toBe("2026-10-02");
  expect(issued.route[0]).toBe("FR");
  expect(issued.seed).toBe(manifest.seed);
  expect(await t.run((ctx) => ctx.db.query("dailyChallenges").take(5))).toHaveLength(1);
});
test("verified submission is atomic, owner-only, and cannot replay twice", async () => {
  vi.useFakeTimers(); const now = Date.UTC(2026, 9, 2); vi.setSystemTime(now);
  const {t, client} = await setup();
  const issued = await client.mutation(api.runs.begin, {mode: "daily", difficulty: "easy"});
  const otherId = await t.run((ctx) => ctx.db.insert("users", {isAnonymous: true}));
  const otherSession = await t.run((ctx) => ctx.db.insert("authSessions", {userId: otherId, expirationTime: Date.now() + 48 * 60 * 60 * 1000}));
  const other = t.withIdentity({subject: `${otherId}|${otherSession}`});
  const balance = BALANCE.easy;
  const events = [{countryIndex: 0, row: 0, lane: laneAt(derivedSeed(issued.seed, 0), 3, 0), atMs: balance.previewMs}];
  vi.setSystemTime(now + 6000);
  const args = {runId: issued.runId, events, endedAtMs: 6000};
  await expect(other.mutation(api.runs.submit, args)).rejects.toThrow("Run not found");
  const result = await client.mutation(api.runs.submit, args);
  expect(result.score).toBe(1);
  expect(result.newBest).toBe(true);
  await expect(client.mutation(api.runs.submit, args)).rejects.toThrow("already submitted");
  const board = await t.query(api.runs.leaderboard, {mode: "daily", difficulty: "easy", date: "2026-10-02"});
  expect(board).toHaveLength(1);
  expect(Object.keys(board[0]).sort()).toEqual(["countries", "displayName", "score"]);
  expect(await t.query(api.runs.leaderboard, {mode: "daily", difficulty: "hard", date: "2026-10-02"})).toEqual([]);
});
test("invalid timing rolls back run and board writes", async () => {
  const {t, client} = await setup();
  const issued = await client.mutation(api.runs.begin, {mode: "daily", difficulty: "hard"});
  await expect(client.mutation(api.runs.submit, {runId: issued.runId, events: [{countryIndex: 0, row: 0, lane: 0, atMs: 0}], endedAtMs: 100})).rejects.toThrow();
  expect((await t.run((ctx) => ctx.db.get(issued.runId)))?.status).toBe("active");
  expect(await t.query(api.runs.leaderboard, {mode: "daily", difficulty: "hard"})).toEqual([]);
});
test("passport conflicts merge discoveries and never write ranking entries", async () => {
  const {t, client} = await setup();
  await client.mutation(api.players.syncPassport, {homeCountry: "FR", discoveries: ["FR"]});
  const result = await client.mutation(api.players.syncPassport, {homeCountry: "JP", discoveries: ["JP"]});
  expect(result).toEqual({homeCountry: "JP", discoveries: ["FR", "JP"]});
  await expect(client.mutation(api.players.syncPassport, {homeCountry: "XX", discoveries: []})).rejects.toThrow();
  expect(await t.run((ctx) => ctx.db.query("leaderboardEntries").take(5))).toEqual([]);
});

test("revoked sessions cannot write with an otherwise signed identity", async () => {
  const {t, client, sessionId} = await setup();
  await t.run((ctx) => ctx.db.delete(sessionId));
  await expect(client.mutation(api.runs.begin, {mode: "infinite", difficulty: "easy"})).rejects.toThrow("Authentication required");
});
test("daily retry stays pinned across midnight", async () => {
  vi.useFakeTimers(); const now = Date.UTC(2026, 9, 2, 23, 59, 58); vi.setSystemTime(now);
  const {client} = await setup();
  const original = await client.mutation(api.runs.begin, {mode: "daily", difficulty: "hard"});
  vi.setSystemTime(now + 5000);
  const retry = await client.mutation(api.runs.begin, {mode: "daily", difficulty: "hard", retryRunId: original.runId});
  expect(retry.date).toBe("2026-10-02");
  expect(retry.route).toEqual(original.route);
  expect(retry.seed).toBe(original.seed);
});
