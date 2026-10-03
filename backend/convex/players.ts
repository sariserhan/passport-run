import { requireUser } from "./authorization";
import { v } from "convex/values";
import { mutation } from "./_generated/server";
import { DESTINATIONS } from "./competition";

export const syncPassport = mutation({
  args: { homeCountry: v.string(), discoveries: v.array(v.string()) },
  returns: v.object({ homeCountry: v.string(), discoveries: v.array(v.string()) }),
  handler: async (ctx, args) => {
    const userId = await requireUser(ctx);
    if (args.discoveries.length > DESTINATIONS.length || args.discoveries.some((id) => !DESTINATIONS.includes(id as typeof DESTINATIONS[number])) || (args.homeCountry !== "" && !DESTINATIONS.includes(args.homeCountry as typeof DESTINATIONS[number]))) throw new Error("Invalid passport");
    const previous = await ctx.db.query("players").withIndex("by_userId", (q) => q.eq("userId", userId)).unique();
    const discoveries = [...new Set([...(previous?.discoveries ?? []), ...args.discoveries])];
    const profile = { homeCountry: args.homeCountry || previous?.homeCountry || "", discoveries };
    if (previous) await ctx.db.patch(previous._id, profile);
    else await ctx.db.insert("players", {userId, ...profile});
    return profile;
  },
});
