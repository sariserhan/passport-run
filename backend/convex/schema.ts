import { authTables } from "@convex-dev/auth/server";
import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

export const difficulty = v.union(v.literal("easy"), v.literal("moderate"), v.literal("hard"));
export const rankedMode = v.union(v.literal("daily"), v.literal("infinite"));
export const manifestFields = {
  mode: rankedMode, difficulty, seed: v.number(), route: v.array(v.string()), date: v.string(),
  catalogVersion: v.optional(v.union(v.literal(1), v.literal(2))),
  generatorVersion: v.literal(1), balanceVersion: v.union(v.literal(1), v.literal(2), v.literal(3)),
};
export default defineSchema({
  ...authTables,
  players: defineTable({ userId: v.id("users"), homeCountry: v.string(), discoveries: v.array(v.string()) })
    .index("by_userId", ["userId"]),
  dailyChallenges: defineTable(manifestFields).index("by_date_difficulty_and_catalog", ["date", "difficulty", "catalogVersion"]),
  runs: defineTable({
    ...manifestFields, userId: v.id("users"), startedAt: v.number(),
    status: v.union(v.literal("active"), v.literal("submitted")),
    score: v.optional(v.number()), countries: v.optional(v.number()),
  }).index("by_userId_and_startedAt", ["userId", "startedAt"]),
  leaderboardEntries: defineTable({
    userId: v.id("users"), board: v.string(), score: v.number(), countries: v.number(),
    runId: v.id("runs"), displayName: v.string(),
  }).index("by_board_and_score", ["board", "score"]).index("by_board_and_userId", ["board", "userId"]),
});
