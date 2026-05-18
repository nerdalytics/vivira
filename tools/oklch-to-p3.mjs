#!/usr/bin/env node
// Regenerate the ViviraColors.xcassets colorsets from tools/colors-source.json.
// Reads oklch and hex values, emits Display P3 components into each colorset's Contents.json.

import { readFileSync, writeFileSync, mkdirSync, existsSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import Color from "colorjs.io";

const __dirname = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(__dirname, "..");
const assetCatalog = resolve(
  repoRoot,
  "Packages/ViviraDesignSystem/Sources/ViviraDesignSystem/Resources/ViviraColors.xcassets"
);
const source = JSON.parse(
  readFileSync(resolve(__dirname, "colors-source.json"), "utf8")
);

function toP3Components(value) {
  const c = new Color(value).to("p3");
  const [r, g, b] = c.coords.map((v) => Math.max(0, Math.min(1, v)));
  return {
    alpha: "1.000",
    red: r.toFixed(3),
    green: g.toFixed(3),
    blue: b.toFixed(3),
  };
}

function writeColorset(path, contents) {
  if (!existsSync(path)) mkdirSync(path, { recursive: true });
  const json = JSON.stringify(contents, null, 2) + "\n";
  const target = resolve(path, "Contents.json");
  if (existsSync(target) && readFileSync(target, "utf8") === json) return;
  writeFileSync(target, json);
}

function neutralColorset(light, dark) {
  return {
    colors: [
      {
        color: {
          "color-space": "display-p3",
          components: toP3Components(light),
        },
        idiom: "universal",
      },
      {
        appearances: [{ appearance: "luminosity", value: "dark" }],
        color: {
          "color-space": "display-p3",
          components: toP3Components(dark),
        },
        idiom: "universal",
      },
    ],
    info: { author: "xcode", version: 1 },
  };
}

function accentColorset(oklch) {
  return {
    colors: [
      {
        color: {
          "color-space": "display-p3",
          components: toP3Components(oklch),
        },
        idiom: "universal",
      },
    ],
    info: { author: "xcode", version: 1 },
  };
}

// Neutrals
for (const [name, variants] of Object.entries(source.neutrals)) {
  const path = resolve(assetCatalog, `${name}.colorset`);
  writeColorset(path, neutralColorset(variants.light, variants.dark));
  console.log(`wrote ${name}.colorset`);
}

// Accents — one colorset per theme × mode
for (const [theme, variants] of Object.entries(source.accents)) {
  for (const mode of ["light", "dark"]) {
    const name = `accent.${theme}.${mode}`;
    const path = resolve(assetCatalog, `${name}.colorset`);
    writeColorset(path, accentColorset(variants[mode]));
    console.log(`wrote ${name}.colorset`);
  }
}

console.log("done.");
