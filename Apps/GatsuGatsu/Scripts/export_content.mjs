#!/usr/bin/env node
// サイト（gatsugatsu-gurume）の constants/*.ts から、アプリに同梱する content.json と写真を作る。
// サイトの記事を更新したら、これを流し直せばアプリにも反映される。
//   node Scripts/export_content.mjs [サイトのフォルダ]
import { execFileSync } from "node:child_process";
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const site = process.argv[2] ?? join(process.env.HOME, "Documents/gatsugatsu-gurume");
const out = join(here, "../GatsuGatsu/Resources");
const load = (name) => import(pathToFileURL(join(site, "constants", `${name}.ts`)).href);

const { COLUMNS, COLUMN_CATEGORIES, getColumn } = await load("columns");
const { getPublishedReports, getReportsByStation } = await load("reports");
const { STATION_PAGES, STATION_REGIONS, getLeadParagraphIndex } = await load("stationPages");
const { getStationGuide } = await load("stationGuides");
const { getStationShopNotes } = await load("editorialNotes");
const { CHAINS, DAILY_REFERENCE, NUTRITION_CHECKED_AT } = await load("calorieData");
const { TABEHOUDAI_CHAINS } = await load("tabehoudaiData");
const { WAIT_TIME_GENRES, SEAT_PRESETS } = await load("waitTimeData");
const quantity = await load("quantity");

// /ryou の表は TSX の中にあるので、配列の部分だけ取り出して評価する。
const ryou = readFileSync(join(site, "app/ryou/page.tsx"), "utf8");
const blocksSource = ryou.match(/const BLOCKS: ColumnBlock\[\] = (\[[\s\S]*?\n\]);/)?.[1];
if (!blocksSource) throw new Error("app/ryou/page.tsx の BLOCKS が見つかりません");
const quantityBlocks = new Function(...Object.keys(quantity), `return ${blocksSource}`)(...Object.values(quantity));

// 駅ページの「続けて読むガイド」の選び方（app/station/[stationName]/page.tsx と同じ）。
const TOPICS = [
  [/二郎|ヤサイ/, "jiro-kei-guide"], [/家系/, "iekei-okonomi"], [/つけ麺/, "tsukemen-menryo"],
  [/油そば|まぜそば/, "aburasoba-guide"], [/町中華|餃子|中華/, "machichuka-tanomikata"],
  [/立ち食い/, "tachigui-soba"], [/カレー/, "curry-topping"], [/とんかつ|丼/, "donburi-zukan"],
  [/定食|ご飯/, "gohan-gram"],
];
const MAP_SEARCHES = [
  ["デカ盛り", "デカ盛り"], ["大盛り無料", "大盛り無料"], ["ご飯おかわり自由", "ご飯 おかわり自由"],
  ["食べ放題", "食べ放題"], ["安くて多い定食", "定食 安い ボリューム"], ["二郎系", "二郎系 ラーメン"],
  ["家系", "家系ラーメン"], ["つけ麺", "つけ麺"], ["町中華", "町中華"], ["とんかつ", "とんかつ"], ["カレー", "カレー"],
].map(([label, keyword]) => ({ label, keyword }));

// 写真は幅1200に縮めて Photos/<スラッグ>.jpg に置き、JSON ではそのスラッグで指す。
mkdirSync(join(out, "Photos"), { recursive: true });
mkdirSync(join(out, "Content"), { recursive: true });
const photo = (src) => {
  const path = join(site, "public", src);
  if (!existsSync(path)) throw new Error(`写真がありません: ${src}`);
  const name = src.replace(/^\/reports\//, "").replace(/\/food\.jpg$/, "").replace(/[/.]/g, "-");
  execFileSync("sips", ["-Z", "1200", "-s", "formatOptions", "78", path, "--out", join(out, "Photos", `${name}.jpg`)], { stdio: "ignore" });
  return name;
};
const withPhotos = (blocks) => blocks.map((b) => (b.type === "photo" ? { ...b, src: photo(b.src) } : b));

const reports = getPublishedReports().map((r) => ({
  ...r,
  heroImage: r.heroImage && { ...r.heroImage, src: photo(r.heroImage.src) },
  blocks: withPhotos(r.blocks),
}));
const columns = COLUMNS.map((c) => ({ ...c, blocks: withPhotos(c.blocks) }));

const stations = STATION_PAGES.map((s) => {
  const guide = getStationGuide(s.name);
  if (!guide) throw new Error(`ガイドがありません: ${s.name}`);
  const paragraphs = guide.split(/\n+/);
  const leadIndex = getLeadParagraphIndex(paragraphs.length);
  const shops = getStationShopNotes(s.name);
  const text = guide + shops.map((x) => x.note).join("");
  const guideSlugs = ["dekamori-sagashikata", ...TOPICS.filter(([p]) => p.test(text)).map(([, slug]) => slug)]
    .filter((slug) => getColumn(slug)).slice(0, 4);
  return {
    name: s.name, region: s.region, hook: s.hook, lines: s.lines, nearby: s.nearby,
    lead: paragraphs[leadIndex],
    sections: paragraphs.filter((_, i) => i !== leadIndex).map((body, i) => ({ heading: s.headings[i] ?? "", body })),
    shops, guideSlugs,
    reportSlugs: getReportsByStation(s.name).map((r) => r.slug),
  };
});

// 記事内のリンク切れを、書き出しの時点で止める。
const reportSlugs = new Set(reports.map((r) => r.slug));
const columnSlugs = new Set(columns.map((c) => c.slug));
const toolPaths = new Set(["/calorie", "/waittime", "/tabehoudai", "/warikan", "/ryou", "/station"]);
const checkLinks = (owner, blocks) => {
  for (const b of blocks) {
    if (b.type === "reportLink" && !reportSlugs.has(b.slug)) console.warn(`  公開していないレポートへのリンク（アプリでは出さない）: ${owner} → ${b.slug}`);
    if (b.type !== "link") continue;
    const ok = toolPaths.has(b.href)
      || (b.href.startsWith("/column/") && columnSlugs.has(b.href.slice(8)))
      || (b.href.startsWith("/report/") && reportSlugs.has(b.href.slice(8)))
      || (b.href.startsWith("/station/") && stations.some((s) => s.name === decodeURIComponent(b.href.slice(9))));
    if (!ok) throw new Error(`アプリで開けないリンク: ${owner} → ${b.href}`);
  }
};
for (const c of columns) checkLinks(c.slug, c.blocks);
for (const r of reports) checkLinks(r.slug, r.blocks);
checkLinks("ryou", quantityBlocks);

const content = {
  categories: COLUMN_CATEGORIES, columns, reports, regions: STATION_REGIONS, stations,
  mapSearches: MAP_SEARCHES, quantityBlocks,
  chains: CHAINS.map(({ stations: _s, ...c }) => c), daily: DAILY_REFERENCE, nutritionCheckedAt: NUTRITION_CHECKED_AT,
  buffets: TABEHOUDAI_CHAINS.map(({ stations: _s, ...c }) => c),
  queueGenres: WAIT_TIME_GENRES.map(({ stations: _s, ...g }) => g), seatPresets: SEAT_PRESETS,
};
writeFileSync(join(out, "Content/content.json"), JSON.stringify(content));
console.log(`columns ${columns.length} / reports ${reports.length} / stations ${stations.length} / chains ${CHAINS.length} / buffets ${TABEHOUDAI_CHAINS.length}`);
