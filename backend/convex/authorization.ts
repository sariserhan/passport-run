import { getAuthSessionId, getAuthUserId } from "@convex-dev/auth/server";
import type { MutationCtx, QueryCtx } from "./_generated/server";

export async function requireUser(ctx: QueryCtx | MutationCtx) {
  const userId = await getAuthUserId(ctx);
  const sessionId = await getAuthSessionId(ctx);
  const session = sessionId ? await ctx.db.get(sessionId) : null;
  if (!userId || !session || session.userId !== userId || session.expirationTime <= Date.now() || !await ctx.db.get(userId)) throw new Error("Authentication required");
  return userId;
}
