import { requireUser } from "./authorization";
import { v } from "convex/values";
import { mutation, query } from "./_generated/server";
import { difficulty, manifestFields, rankedMode } from "./schema";
import { boardKey, manifestFor, verifyReplay } from "./competition";

export const daily = query({
  args: { difficulty }, returns: v.object(manifestFields),
  handler: async (_ctx, args) => manifestFor("daily", args.difficulty, Date.now()),
});
export const begin = mutation({
  args: { mode: rankedMode, difficulty, retryRunId: v.optional(v.id("runs")) },
  returns: v.object({ runId: v.id("runs"), ...manifestFields }),
  handler: async (ctx, args) => {
    const userId = await requireUser(ctx);
    const now = Date.now();
    const previous = await ctx.db.query("runs").withIndex("by_userId_and_startedAt", (q) => q.eq("userId", userId)).order("desc").first();
    if (previous && now - previous.startedAt < 1000) throw new Error("Please wait before starting another run");
    let manifest = manifestFor(args.mode, args.difficulty, now);
    if (args.retryRunId) {
      const original = await ctx.db.get(args.retryRunId);
      if (!original || original.userId !== userId || original.mode !== args.mode || original.difficulty !== args.difficulty || now - original.startedAt > 48 * 60 * 60 * 1000) throw new Error("Invalid retry");
      manifest = {mode: original.mode, difficulty: original.difficulty, seed: original.seed, route: original.route, date: original.date, generatorVersion: original.generatorVersion, balanceVersion: original.balanceVersion, ...(original.catalogVersion ? {catalogVersion: original.catalogVersion} : {})};
    }
    if (args.mode === "daily") {
      const sameCatalog = await ctx.db.query("dailyChallenges").withIndex("by_date_difficulty_and_catalog", (q) => q.eq("date", manifest.date).eq("difficulty", args.difficulty).eq("catalogVersion", manifest.catalogVersion)).unique();
      if (sameCatalog) {
        manifest.seed = sameCatalog.seed;
        manifest.route = sameCatalog.route;
      } else await ctx.db.insert("dailyChallenges", manifest);
    }
    const runId = await ctx.db.insert("runs", { ...manifest, userId, startedAt: now, status: "active" });
    return { runId, ...manifest };
  },
});
export const submit = mutation({
  args: {
    runId: v.id("runs"),
    events: v.array(v.object({countryIndex: v.number(), row: v.number(), lane: v.number(), atMs: v.number(), decisionMs: v.optional(v.number())})),
    endedAtMs: v.number(),
  },
  returns: v.object({score: v.number(), countries: v.number(), board: v.string(), newBest: v.boolean()}),
  handler: async (ctx, args) => {
    const userId = await requireUser(ctx);
    const run = await ctx.db.get(args.runId);
    if (!run || run.userId !== userId) throw new Error("Run not found");
    if (run.status !== "active") throw new Error("Run already submitted");
    const elapsed = Date.now() - run.startedAt;
    if (elapsed > 48 * 60 * 60 * 1000) throw new Error("Run expired");
    const verified = verifyReplay(run, args.events, args.endedAtMs, elapsed);
    const board = boardKey(run);
    await ctx.db.patch(run._id, { status: "submitted", ...verified });
    const previous = await ctx.db.query("leaderboardEntries").withIndex("by_board_and_userId", (q) => q.eq("board", board).eq("userId", userId)).unique();
    const newBest = !previous || verified.score > previous.score;
    if (newBest) {
      // Generated alias only: no free-form usernames, emails, or account IDs in public responses.
      let hash = 0;
      for (const char of userId) hash = (hash * 31 + char.charCodeAt(0)) >>> 0;
      const entry = { userId, board, ...verified, runId: run._id, displayName: `Explorer${String(hash % 10000).padStart(4, "0")}` };
      if (previous) await ctx.db.replace(previous._id, entry);
      else await ctx.db.insert("leaderboardEntries", entry);
    }
    return { ...verified, board, newBest };
  },
});
export const leaderboard = query({
  args: { mode: rankedMode, difficulty, date: v.optional(v.string()) },
  returns: v.array(v.object({displayName: v.string(), score: v.number(), countries: v.number()})),
  handler: async (ctx, args) => {
    const manifest = manifestFor(args.mode, args.difficulty, Date.now());
    if (args.mode === "daily" && args.date !== undefined) {
      if (!/^\d{4}-\d{2}-\d{2}$/.test(args.date) || Number.isNaN(Date.parse(args.date)) || new Date(args.date).toISOString().slice(0, 10) !== args.date) throw new Error("Invalid date");
      manifest.date = args.date;
    }
    const rows = await ctx.db.query("leaderboardEntries").withIndex("by_board_and_score", (q) => q.eq("board", boardKey(manifest))).order("desc").take(50);
    return rows.map(({displayName, score, countries}) => ({displayName, score, countries}));
  },
});
