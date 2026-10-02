// Generates ephemeral keys for local Convex Auth only. Never prints private key material.
import { generateKeyPair, exportJWK, exportPKCS8 } from "jose";
import { writeFile } from "node:fs/promises";
const destination = process.argv[2];
if (!destination) throw new Error("Pass a private temporary output path");
const {privateKey, publicKey} = await generateKeyPair("RS256", {extractable: true});
const jwk = await exportJWK(publicKey);
jwk.use = "sig";
jwk.kid = "passport-local";
await writeFile(destination, `JWT_PRIVATE_KEY=${JSON.stringify(await exportPKCS8(privateKey))}\nJWKS='${JSON.stringify({keys: [jwk]})}'\n`, {mode: 0o600});
