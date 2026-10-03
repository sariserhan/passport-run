import { describe, expect, test } from "vitest";
import { BALANCE, boardKey, dailySeed, derivedSeed, laneAt, manifestFor, routeFrom, verifyReplay } from "../convex/competition";
import type { Difficulty, Manifest, Selection } from "../convex/competition";
import fixtures from "./fixtures/v1.json";

function validRun(manifest: Manifest, rows = 20): { events: Selection[]; end: number } {
  const balance = BALANCE[manifest.difficulty];
  const events: Selection[] = [];
  const previewMs = manifest.balanceVersion >= 3 ? 3000 : balance.previewMs;
  let atMs = previewMs;
  for (let index = 0; index < rows; index++) {
    const countryIndex = manifest.mode === "daily" ? Math.floor(index / balance.rows) : 0;
    const row = manifest.mode === "daily" ? index % balance.rows : index;
    const seed = manifest.mode === "daily" ? derivedSeed(manifest.seed, countryIndex) : manifest.seed;
    events.push({ countryIndex, row, lane: laneAt(seed, balance.lanes, row), atMs, decisionMs: 0 });
    atMs += balance.jumpMs;
    if ((index + 1) % balance.rows === 0) atMs += previewMs + (manifest.mode === "daily" ? 500 : 0);
  }
  return { events, end: atMs };
}
describe("v1 cross-language compatibility", () => {
  for (const fixture of fixtures.lanes) test(`lane ${fixture.seed}/${fixture.lanes}/${fixture.row}`, () => expect(laneAt(fixture.seed, fixture.lanes, fixture.row)).toBe(fixture.lane));
  for (const fixture of fixtures.routes) test(`route ${fixture.home}/${fixture.seed}`, () => expect(routeFrom(fixture.home, fixture.seed, 1)).toEqual(fixture.route));
  for (const fixture of fixtures.daily) test(`daily ${fixture.date}/${fixture.difficulty}`, () => expect(dailySeed(fixture.date, fixture.difficulty as Difficulty)).toBe(fixture.seed));
  test("immutable balance matches Godot", () => expect(BALANCE).toEqual(fixtures.balance));
});
describe("replay validation", () => {
  const manifest = manifestFor("daily", "easy", Date.UTC(2026, 9, 2));
  test("full daily score comes from selections", () => {
    const { events, end } = validRun(manifest, 50);
    expect(verifyReplay(manifest, events, end, end)).toEqual({score: 50, countries: 5});
  });
  test("infinite section previews are enforced", () => {
    const infinite = manifestFor("infinite", "hard", 0);
    const { events, end } = validRun(infinite, 50);
    expect(verifyReplay(infinite, events, end, end).score).toBe(50);
    events[20].atMs -= 3000;
    expect(() => verifyReplay(infinite, events, end, end)).toThrow();
  });
  test.each(["skip", "duplicate", "lane", "fraction", "speed", "future", "after-failure", "overflow"])("rejects %s", (kind) => {
    const { events, end } = validRun(manifest, 20);
    if (kind === "skip") events[1].row++;
    if (kind === "duplicate") events[1].row--;
    if (kind === "lane") events[1].lane = 3;
    if (kind === "fraction") events[1].atMs += 0.5;
    if (kind === "speed") events[1].atMs = events[0].atMs + 1;
    if (kind === "after-failure") events[0].lane = (events[0].lane + 1) % 3;
    if (kind === "overflow") while (events.length <= 4096) events.push(events[0]);
    expect(() => verifyReplay(manifest, events, end, kind === "future" ? end - 1000 : end)).toThrow();
  });
  test("failure contributes no safe score", () => {
    const { events, end } = validRun(manifest, 1);
    events[0].lane = (events[0].lane + 1) % 3;
    expect(verifyReplay(manifest, events, end, end)).toEqual({score: 0, countries: 0});
  });
  test("boards separate all identities", () => {
    expect(boardKey(manifest)).not.toBe(boardKey(manifestFor("daily", "hard", Date.UTC(2026, 9, 2))));
    expect(boardKey(manifest)).not.toBe(boardKey(manifestFor("daily", "easy", Date.UTC(2026, 9, 3))));
    expect(boardKey(manifest)).not.toBe(boardKey(manifestFor("infinite", "easy", 0)));
    expect(boardKey(manifest)).not.toBe(boardKey({...manifest, balanceVersion: 1}));
  });
  test.each([undefined, -1, 10001, 1.5, Number.NaN])("v2 rejects invalid decision time %s", (decisionMs) => {
    const {events, end} = validRun(manifest, 1);
    events[0].decisionMs = decisionMs;
    expect(() => verifyReplay(manifest, events, end, end)).toThrow();
  });
  test("v1 replays keep their original untimed rules", () => {
    const {events, end} = validRun({...manifest, balanceVersion: 1}, 1);
    delete events[0].decisionMs;
    expect(verifyReplay({...manifest, balanceVersion: 1}, events, end, end).score).toBe(1);
  });
  test("decision time cannot exceed the recorded available elapsed time", () => {
    const {events, end} = validRun(manifest, 1);
    events[0].decisionMs = 10000;
    expect(() => verifyReplay(manifest, events, end, end)).toThrow();
    events[0].atMs += 10000;
    expect(verifyReplay(manifest, events, end + 10000, end + 10000).score).toBe(1);
  });
});


test("expanded catalog routes and boards stay deterministic and separate from legacy", () => {
  const current = manifestFor("daily", "hard", 0);
  for (const home of ["AE", "DE", "KR", "JM", "BO", "NZ"]) {
    const route = routeFrom(home, 88);
    expect(route).toHaveLength(197);
    expect(new Set(route).size).toBe(197);
    expect(route[0]).toBe(home);
    expect(route).toEqual(routeFrom(home, 88));
  }
  expect(boardKey(current)).not.toBe(boardKey({...current, catalogVersion: undefined}));
  const {events, end} = validRun(current, 3940);
  expect(verifyReplay(current, events, end, end)).toEqual({score: 3940, countries: 197});
});

 test("three-second previews apply to every new difficulty while legacy timing stays intact", () => {
  for (const difficulty of ["easy", "moderate", "hard"] as Difficulty[]) {
    const manifest = manifestFor("infinite", difficulty, 0);
    expect(manifest.balanceVersion).toBe(3);
    const event = {countryIndex: 0, row: 0, lane: laneAt(manifest.seed, BALANCE[difficulty].lanes, 0), atMs: 3000, decisionMs: 0};
    expect(verifyReplay(manifest, [event], 3380, 3380).score).toBe(1);
    expect(() => verifyReplay(manifest, [{...event, atMs: 2999}], 3380, 3380)).toThrow();
    const old = {...manifest, balanceVersion: 2 as const};
    const oldAt = BALANCE[difficulty].previewMs;
    expect(verifyReplay(old, [{...event, atMs: oldAt}], oldAt + 380, oldAt + 380).score).toBe(1);
    expect(boardKey(old)).not.toBe(boardKey(manifest));
  }
});
