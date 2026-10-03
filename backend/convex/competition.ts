// Generator/presets v1 stay immutable; balance v2 adds the decision deadline.
export const MODULUS = 2147483647n;
import destinations from "../../resources/geography/destinations.json";
import territories from "../../resources/geography/territories.json";
import fantasy from "../../resources/geography/fantasy.json";
import landmarks from "../../resources/geography/landmarks.json";
import cinema from "../../resources/geography/cinema.json";
export const COUNTRIES = Object.keys(destinations);
export const DESTINATIONS = Object.keys({...destinations, ...territories, ...landmarks, ...fantasy, ...cinema});
const legacyCountries = ["US", "FR", "EG", "TR", "JP"];
const geography: Record<string, {neighbors: string[]}> = destinations;
export type Difficulty = "easy" | "moderate" | "hard";
export type Mode = "daily" | "infinite";
export const BALANCE = {
  easy: { lanes: 3, rows: 10, previewMs: 5000, jumpMs: 380 },
  moderate: { lanes: 4, rows: 14, previewMs: 3000, jumpMs: 380 },
  hard: { lanes: 5, rows: 20, previewMs: 2000, jumpMs: 380 },
} as const;
export const MAX_EVENTS = 4096;
export const DECISION_MS = 10000;
const legacyNeighbors: Record<string, string[]> = { US: ["FR"], FR: ["TR"], EG: ["TR"], TR: ["FR", "EG"], JP: [] };

export function laneAt(seed: number, lanes: number, row: number): number {
  if (!Number.isSafeInteger(seed) || !Number.isInteger(lanes) || lanes < 1 || !Number.isSafeInteger(row) || row < 0) throw new Error("Invalid generator input");
  let exponent = BigInt(row) + 1n;
  let factor = 48271n;
  let multiplier = 1n;
  while (exponent > 0n) {
    if (exponent & 1n) multiplier = multiplier * factor % MODULUS;
    factor = factor * factor % MODULUS;
    exponent >>= 1n;
  }
  const normalized = ((BigInt(seed) % (MODULUS - 1n)) + MODULUS - 1n) % (MODULUS - 1n) + 1n;
  return Number(normalized * multiplier % MODULUS % BigInt(lanes));
}
export function derivedSeed(seed: number, index: number): number {
  return ((seed % 2147483646 + 2147483646) % 2147483646 + index * 104729) % 2147483646;
}
export function dailySeed(date: string, difficulty: Difficulty): number {
  let value = 5381;
  for (const char of `passport-daily-v1:${date}:${difficulty}`) value = (value * 33 + char.charCodeAt(0)) % 2147483646;
  return value;
}
export function routeFrom(home: string, seed: number, catalogVersion = 2): string[] {
  const countries = catalogVersion === 1 ? legacyCountries : COUNTRIES;
  const neighbors = catalogVersion === 1 ? legacyNeighbors : Object.fromEntries(countries.map((id) => [id, geography[id].neighbors]));
  if (!countries.includes(home)) throw new Error("Unknown country");
  const route = [home];
  while (route.length < countries.length) {
    const current = route[route.length - 1];
    const remaining = countries.filter((id) => !route.includes(id));
    const nearby = neighbors[current].filter((id) => remaining.includes(id as typeof COUNTRIES[number]));
    const choiceSeed = derivedSeed(seed, route.length);
    const flight = nearby.length === 0 || route.length % 3 === 0 || laneAt(choiceSeed, 100, 0) >= 80;
    const pool = flight ? remaining : nearby;
    route.push(pool[laneAt(choiceSeed, pool.length, 1)]);
  }
  return route;
}
export interface Manifest {
  mode: Mode; difficulty: Difficulty; seed: number; route: string[]; date: string;
  generatorVersion: 1; balanceVersion: 1 | 2 | 3; catalogVersion?: 1 | 2;
}
export function manifestFor(mode: Mode, difficulty: Difficulty, now: number): Manifest {
  const date = mode === "daily" ? new Date(now).toISOString().slice(0, 10) : "";
  const seed = dailySeed(mode === "daily" ? date : "infinite-v1", difficulty);
  return { mode, difficulty, seed, route: mode === "daily" ? routeFrom("FR", seed) : [], date, generatorVersion: 1, balanceVersion: 3, catalogVersion: 2 };
}
export interface Selection { countryIndex: number; row: number; lane: number; atMs: number; decisionMs?: number }
export function verifyReplay(manifest: Manifest, events: Selection[], endedAtMs: number, serverElapsedMs: number): {score: number; countries: number} {
  if (manifest.generatorVersion !== 1 || ![1, 2, 3].includes(manifest.balanceVersion) || !BALANCE[manifest.difficulty]) throw new Error("Unsupported rules");
  if (events.length > MAX_EVENTS || !Number.isSafeInteger(endedAtMs) || endedAtMs < 0 || endedAtMs > serverElapsedMs + 250) throw new Error("Invalid elapsed time or event limit");
  const balance = BALANCE[manifest.difficulty];
  let countryIndex = 0, row = 0, score = 0, countries = 0;
  const previewMs = manifest.balanceVersion >= 3 ? 3000 : balance.previewMs;
  let earliest = previewMs;
  let failed = false;
  for (const event of events) {
    if (failed || (manifest.mode === "daily" && countryIndex >= manifest.route.length)) throw new Error("Events after run ended");
    if (![event.countryIndex, event.row, event.lane, event.atMs].every(Number.isSafeInteger) || event.countryIndex !== countryIndex || event.row !== row || event.lane < 0 || event.lane >= balance.lanes || event.atMs < earliest || event.atMs + balance.jumpMs > endedAtMs) throw new Error("Invalid row, lane, or timing");
    if (manifest.balanceVersion >= 2 && (!Number.isSafeInteger(event.decisionMs) || event.decisionMs! < 0 || event.decisionMs! > DECISION_MS || event.decisionMs! > event.atMs - earliest + 250)) throw new Error("Invalid decision time");
    const seed = manifest.mode === "infinite" ? manifest.seed : derivedSeed(manifest.seed, countryIndex);
    if (event.lane !== laneAt(seed, balance.lanes, row)) { failed = true; continue; }
    score++;
    row++;
    earliest = event.atMs + balance.jumpMs;
    if (manifest.mode === "daily" && row === balance.rows) {
      countries++;
      countryIndex++;
      row = 0;
      earliest += 500 + previewMs;
    } else if (manifest.mode === "infinite" && row % balance.rows === 0) {
      earliest += previewMs;
    }
  }
  return { score, countries };
}
export function boardKey(manifest: Manifest): string {
  return `${manifest.mode}:${manifest.difficulty}:${manifest.date}:g1:b${manifest.balanceVersion}${manifest.catalogVersion === 2 ? ":c2" : ""}`;
}
