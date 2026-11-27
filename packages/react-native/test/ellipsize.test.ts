import { test } from "node:test";
import assert from "node:assert/strict";
import { ELLIPSIS, ellipsize } from "../src/ellipsize.ts";

const measure = (text: string) => Array.from(text).length * 10;

test("text that fits is left alone", () => {
  assert.equal(ellipsize("Searching", 90, measure), "Searching");
  assert.equal(ellipsize("Searching", 500, measure), "Searching");
});

test("long text ends in an ellipsis within the width", () => {
  const cut = ellipsize("Using lookup customer records", 100, measure);
  assert.equal(cut, "Using loo" + ELLIPSIS);
  assert.ok(measure(cut) <= 100);
});

test("a trailing space is dropped before the ellipsis", () => {
  assert.equal(ellipsize("Using lookup", 70, measure), "Using" + ELLIPSIS);
});

test("characters outside the basic plane are never split", () => {
  assert.equal(ellipsize("\u{1F50D}\u{1F50D}\u{1F50D}\u{1F50D}", 30, measure), "\u{1F50D}\u{1F50D}" + ELLIPSIS);
});

test("no room even for the ellipsis gives empty text", () => {
  assert.equal(ellipsize("Searching", 5, measure), "");
});
