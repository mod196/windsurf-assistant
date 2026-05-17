#!/usr/bin/env node
// 印 142 · 反者道之动 · spam-flag 第二层 Actions disabled · 守门测
// ════════════════════════════════════════════════════════════════════════
// 帛书四十「反者道之动也 · 弱者道之用也」
// 帛书十六「致虚极守静督 · 万物旁作 · 吾以观其复也 · 归根曰静 · 静曰复命」
// 帛书四十三「天下之至柔 · 驰骋于天下之致坚 · 无有入于无间」
// 帛书六十四「慎终若始 · 则无败事矣」
//
// 守门 6 章 (承 cascade A 之印 142 文献 § 6 · 补 cascade A 之遗):
//   §1 · docs/印142_反者道之动_Actions禁用第二层_*.md 存
//   §2 · docs/印142_spec镜像对齐_道生镜_*.md 存
//   §3 · 印 142 主文献含「Actions has been disabled」关键真证
//   §4 · 印 142 主文献含帛书四十 / 帛书十六 / 帛书四十三
//   §5 · 印 142 主文献含承印 141 + 第二层之承前关系
//   §6 · 印 142 主文献含真用户测端点 A12 = e8a0575 (与本会话 mcp1 视角同源)
// ════════════════════════════════════════════════════════════════════════
"use strict";

const fs = require("fs");
const path = require("path");

const ROOT = path.resolve(__dirname, "..");
const DOCS = path.join(ROOT, "docs");

const tests = [];
function test(name, fn) {
  try {
    fn();
    tests.push({ name, ok: true });
    console.log(`  ✓ ${name}`);
  } catch (e) {
    tests.push({ name, ok: false, err: e.message });
    console.log(`  ✗ ${name} · ${e.message}`);
  }
}

function assert(cond, msg) {
  if (!cond) throw new Error(msg);
}

console.log("");
console.log("═══ 印 142 · 反者道之动 · spam-flag 第二层 · 守门测 ═══");
console.log("");

const docsList = fs.readdirSync(DOCS);

// ────────────────────────────────────────────────────────────────
// §1 · docs/印142_反者道之动_Actions禁用第二层_*.md 存
// ────────────────────────────────────────────────────────────────
console.log("§1 · 印 142 主文献 (Actions 禁用第二层) 存");

let yin142MainFile = null;
test("docs/印142_反者道之动_Actions禁用第二层_*.md 存", () => {
  yin142MainFile = docsList.find((f) =>
    /^印142[_\u00b7\s].*Actions.*禁用.*第二层.*\.md$/.test(f),
  );
  assert(yin142MainFile, "印 142 主文献 (Actions 禁用第二层) 不存");
});

// ────────────────────────────────────────────────────────────────
// §2 · docs/印142_spec镜像对齐_道生镜_*.md 存
// ────────────────────────────────────────────────────────────────
console.log("");
console.log("§2 · 印 142 spec 镜像文献存");

test("docs/印142_spec镜像对齐_道生镜_*.md 存", () => {
  const found = docsList.find((f) =>
    /^印142[_\u00b7\s].*spec.*镜像.*道生镜.*\.md$/i.test(f),
  );
  assert(found, "印 142 spec 镜像文献 (道生镜) 不存");
});

// ────────────────────────────────────────────────────────────────
// §3 · 印 142 主文献含「Actions has been disabled」关键真证
// ────────────────────────────────────────────────────────────────
console.log("");
console.log("§3 · 关键真证 · Actions has been disabled");

test("印 142 主文献含「Actions has been disabled」", () => {
  assert(yin142MainFile, "印 142 主文献缺");
  const content = fs.readFileSync(path.join(DOCS, yin142MainFile), "utf-8");
  assert(
    /Actions has been disabled/i.test(content),
    "印 142 文献缺「Actions has been disabled」关键真证",
  );
});

test("印 142 主文献含 422 状态码 (真用户测 actions/dispatches)", () => {
  const content = fs.readFileSync(path.join(DOCS, yin142MainFile), "utf-8");
  assert(/422/.test(content), "印 142 文献缺 422 状态码 (Actions disabled 之真返)");
});

// ────────────────────────────────────────────────────────────────
// §4 · 印 142 主文献含帛书四十 / 帛书十六 / 帛书四十三
// ────────────────────────────────────────────────────────────────
console.log("");
console.log("§4 · 帛书引 · 四十 / 十六 / 四十三");

test("印 142 文献含帛书四十「反者道之动」", () => {
  const content = fs.readFileSync(path.join(DOCS, yin142MainFile), "utf-8");
  assert(
    /帛书四十.*反者道之动|反者道之动.*帛书四十/.test(content),
    "印 142 文献缺帛书四十「反者道之动」",
  );
});

test("印 142 文献含帛书十六「致虚极」或「归根曰静」", () => {
  const content = fs.readFileSync(path.join(DOCS, yin142MainFile), "utf-8");
  assert(
    /帛书十六.*(致虚极|归根曰静|复命)|(致虚极|归根曰静|复命).*帛书十六/.test(
      content,
    ),
    "印 142 文献缺帛书十六",
  );
});

test("印 142 文献含帛书四十三「天下之至柔」或「入于无间」", () => {
  const content = fs.readFileSync(path.join(DOCS, yin142MainFile), "utf-8");
  assert(
    /帛书四十三.*(至柔|无间)|(至柔|无间).*帛书四十三/.test(content),
    "印 142 文献缺帛书四十三",
  );
});

// ────────────────────────────────────────────────────────────────
// §5 · 承印 141 + 第二层之承前关系
// ────────────────────────────────────────────────────────────────
console.log("");
console.log("§5 · 承印 141 + 第二层");

test("印 142 文献含「印 141」承前", () => {
  const content = fs.readFileSync(path.join(DOCS, yin142MainFile), "utf-8");
  assert(/印 141/.test(content), "印 142 文献缺承印 141");
});

test("印 142 文献含「第一层」+「第二层」", () => {
  const content = fs.readFileSync(path.join(DOCS, yin142MainFile), "utf-8");
  assert(/第一层/.test(content), "印 142 文献缺「第一层」(git smart-http)");
  assert(/第二层/.test(content), "印 142 文献缺「第二层」(Actions disabled)");
});

// ────────────────────────────────────────────────────────────────
// §6 · 真用户测端点 A12 = e8a0575 (与 mcp1 视角同源)
// ────────────────────────────────────────────────────────────────
console.log("");
console.log("§6 · 真用户测 A12 · 远端 main HEAD = e8a0575 (印 141 末态)");

test("印 142 文献含真用户测 A12 之实证", () => {
  const content = fs.readFileSync(path.join(DOCS, yin142MainFile), "utf-8");
  assert(
    /e8a0575|git\/refs\/heads\/main/.test(content),
    "印 142 文献缺 A12 真证 (远端 main HEAD sha)",
  );
});

test("印 142 文献含 cascade A 之径 PAT-curl REST API", () => {
  const content = fs.readFileSync(path.join(DOCS, yin142MainFile), "utf-8");
  assert(
    /PAT-curl|REST API|CredRead|wincred/i.test(content),
    "印 142 文献缺 cascade A 之径 (PAT-curl / Win32 CredRead)",
  );
});

// ────────────────────────────────────────────────────────────────
// 总结
// ────────────────────────────────────────────────────────────────
console.log("");
const ok = tests.filter((t) => t.ok).length;
const fail = tests.length - ok;

if (fail === 0) {
  console.log(`✓ 印 142 反者道之动 · Actions 禁用第二层 · ${ok}/${tests.length} 通`);
  console.log("  反者道之动 · 弱者道之用 · 帛书四十");
  console.log("");
  process.exit(0);
} else {
  console.log(`✗ 印 142 守门 · ${fail} 败 / ${tests.length}`);
  tests.filter((t) => !t.ok).forEach((t) => console.log(`  · ${t.name}: ${t.err}`));
  process.exit(1);
}
