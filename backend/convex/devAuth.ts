// Loopback-only adapter: Convex Auth 0.0.96 omits JWT kid headers, while the
// local custom-JWT verifier requires them. Hosted clients use auth:signIn.
import { v } from "convex/values";
import { decodeJwt, importPKCS8, SignJWT } from "jose";
import { action } from "./_generated/server";
import { api } from "./_generated/api";

export const signIn = action({
  args: { provider: v.optional(v.literal("anonymous")), refreshToken: v.optional(v.string()) },
  returns: v.object({ tokens: v.object({token: v.string(), refreshToken: v.string()}) }),
  handler: async (ctx, args): Promise<{tokens: {token: string; refreshToken: string}}> => {
    if (!/^http:\/\/(127\.0\.0\.1|localhost):\d+$/.test(process.env.CONVEX_SITE_URL ?? "")) throw new Error("Local development only");
    const issued = await ctx.runAction(api.auth.signIn, args);
    if (!issued.tokens) throw new Error("Sign-in failed");
    const privateKey = await importPKCS8(process.env.JWT_PRIVATE_KEY!, "RS256");
    // Claims come exclusively from the real server-issued Convex Auth token.
    const token = await new SignJWT(decodeJwt(issued.tokens.token))
      .setProtectedHeader({alg: "RS256", kid: "passport-local", typ: "JWT"})
      .sign(privateKey);
    return {tokens: {token, refreshToken: issued.tokens.refreshToken}};
  },
});
