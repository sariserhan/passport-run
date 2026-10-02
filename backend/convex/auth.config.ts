import type { AuthConfig } from "convex/server";

const issuer = process.env.CONVEX_SITE_URL;
// Local OIDC discovery cannot fetch loopback HTTP. Verify the same signatures,
// issuer and audience against inline public keys; hosted deployments use OIDC.
export default {
  providers: issuer?.startsWith("http://127.0.0.1:") || issuer?.startsWith("http://localhost:")
    ? [{type: "customJwt", issuer, applicationID: "convex", algorithm: "RS256", jwks: `data:text/plain;charset=utf-8;base64,${btoa(process.env.JWKS ?? "")}`}]
    : [{ domain: issuer!, applicationID: "convex" }],
} satisfies AuthConfig;


