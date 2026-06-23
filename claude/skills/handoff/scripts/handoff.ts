import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

const TTL_MS = 7776000000; // 90 days
const INDEX_KEY = "handoff:_index";
const SLUG_REGEX = /^[a-z0-9][a-z0-9_-]{0,79}$/;
const HANDOFF_KEY_PREFIX = "handoff:";

function loadUpstashFromFile(): { url?: string; token?: string } {
  try {
    const text = readFileSync(join(homedir(), ".upstash"), "utf8");
    const out: { url?: string; token?: string } = {};
    for (const line of text.split("\n")) {
      const trimmed = line.trim();
      if (trimmed.length === 0 || trimmed.startsWith("#")) continue;
      const m = trimmed.match(/^(?:export\s+)?([A-Z_][A-Z0-9_]*)=(.*)$/);
      if (!m) continue;
      let val = m[2];
      if (
        (val.startsWith('"') && val.endsWith('"')) ||
        (val.startsWith("'") && val.endsWith("'"))
      ) {
        val = val.slice(1, -1);
      }
      if (m[1] === "UPSTASH_REDIS_REST_URL") out.url = val;
      else if (m[1] === "UPSTASH_REDIS_REST_TOKEN") out.token = val;
    }
    return out;
  } catch {
    return {};
  }
}

// File is canonical (per user convention) — env vars in the parent shell can be
// stale after Upstash re-provisioning. Read the file first; fall back to env
// vars only if the file is missing or doesn't contain the value.
const fileCreds = loadUpstashFromFile();

const UPSTASH_URL = fileCreds.url ?? process.env.UPSTASH_REDIS_REST_URL;
const UPSTASH_TOKEN = fileCreds.token ?? process.env.UPSTASH_REDIS_REST_TOKEN;

if (!UPSTASH_URL || !UPSTASH_TOKEN) {
  process.stderr.write(
    "missing UPSTASH_REDIS_REST_URL / UPSTASH_REDIS_REST_TOKEN — set env vars or write `export UPSTASH_REDIS_REST_URL=...` and `export UPSTASH_REDIS_REST_TOKEN=...` to ~/.upstash\n",
  );
  process.exit(2);
}

class UpstashError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "UpstashError";
  }
}

async function upstashCall(...args: (string | number)[]): Promise<unknown> {
  const body = JSON.stringify(args.map(String));
  let res: Response;
  try {
    res = await fetch(UPSTASH_URL!, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${UPSTASH_TOKEN}`,
        "Content-Type": "application/json",
      },
      body,
    });
  } catch (e) {
    throw new UpstashError(
      `cannot reach Upstash REST API at $UPSTASH_REDIS_REST_URL\ncheck $UPSTASH_REDIS_REST_TOKEN and network connectivity\n(${(e as Error).message})`,
    );
  }
  if (!res.ok) {
    throw new UpstashError(`Upstash HTTP ${res.status}: ${await res.text()}`);
  }
  const json = (await res.json()) as { result?: unknown; error?: string };
  if (json.error) throw new UpstashError(json.error);
  return json.result;
}

async function upstashPipeline(
  commands: (string | number)[][],
): Promise<unknown[]> {
  const url = `${UPSTASH_URL!.replace(/\/$/, "")}/pipeline`;
  let res: Response;
  try {
    res = await fetch(url, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${UPSTASH_TOKEN}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(commands.map((cmd) => cmd.map(String))),
    });
  } catch (e) {
    throw new UpstashError(
      `cannot reach Upstash REST API at $UPSTASH_REDIS_REST_URL\ncheck $UPSTASH_REDIS_REST_TOKEN and network connectivity\n(${(e as Error).message})`,
    );
  }
  if (!res.ok) {
    throw new UpstashError(`Upstash HTTP ${res.status}: ${await res.text()}`);
  }
  const json = (await res.json()) as { result?: unknown; error?: string }[];
  return json.map((entry) => {
    if (entry.error) throw new UpstashError(entry.error);
    return entry.result;
  });
}

function validateSlug(slug: string): void {
  if (!SLUG_REGEX.test(slug)) {
    process.stderr.write(
      `invalid slug "${slug}"\nslugs must match ${SLUG_REGEX} (lowercase, kebab/snake, ≤80 chars, no slashes)\n`,
    );
    process.exit(1);
  }
}

function handoffKey(slug: string): string {
  return `${HANDOFF_KEY_PREFIX}${slug}`;
}

function levenshtein(a: string, b: string): number {
  const m = a.length;
  const n = b.length;
  if (m === 0) return n;
  if (n === 0) return m;
  const prev = new Array<number>(n + 1);
  const curr = new Array<number>(n + 1);
  for (let j = 0; j <= n; j++) prev[j] = j;
  for (let i = 1; i <= m; i++) {
    curr[0] = i;
    for (let j = 1; j <= n; j++) {
      const cost = a[i - 1] === b[j - 1] ? 0 : 1;
      curr[j] = Math.min(curr[j - 1] + 1, prev[j] + 1, prev[j - 1] + cost);
    }
    for (let j = 0; j <= n; j++) prev[j] = curr[j];
  }
  return prev[n];
}

function findNearestSlugs(
  input: string,
  allSlugs: string[],
  max = 3,
): string[] {
  return allSlugs
    .map((slug) => ({ slug, dist: levenshtein(input, slug) }))
    .sort((a, b) => a.dist - b.dist || a.slug.localeCompare(b.slug))
    .slice(0, max)
    .map((entry) => entry.slug);
}

function ageString(isoOrMs: string | number): string {
  const ts = typeof isoOrMs === "number" ? isoOrMs : Date.parse(isoOrMs);
  const diffMs = Date.now() - ts;
  const sec = Math.floor(diffMs / 1000);
  if (sec < 60) return `${sec}s ago`;
  const min = Math.floor(sec / 60);
  if (min < 60) return `${min}m ago`;
  const hr = Math.floor(min / 60);
  if (hr < 48) return `${hr}h ago`;
  const day = Math.floor(hr / 24);
  if (day < 60) return `${day}d ago`;
  const month = Math.floor(day / 30);
  return `${month}mo ago`;
}

async function listAllSlugs(): Promise<string[]> {
  const result = (await upstashCall(
    "ZRANGE",
    INDEX_KEY,
    0,
    -1,
  )) as string[] | null;
  return result ?? [];
}

// Upstash REST returns HGETALL as a flat array [k1, v1, k2, v2, ...].
// (The @upstash/redis SDK normalizes to an object; we don't.)
function parseHashArray(raw: unknown): Record<string, string> {
  if (raw === null || raw === undefined) return {};
  if (!Array.isArray(raw)) {
    // Defensive: in case Upstash ever returns object form, accept it.
    if (typeof raw === "object") return raw as Record<string, string>;
    return {};
  }
  const out: Record<string, string> = {};
  for (let i = 0; i + 1 < raw.length; i += 2) {
    out[String(raw[i])] = String(raw[i + 1]);
  }
  return out;
}

function notFoundMessage(slug: string, nearest: string[]): string {
  if (nearest.length === 0) {
    return `no such handoff "${slug}"\nnone known. (run \`handoff list\`)\n`;
  }
  return `no such handoff "${slug}"\ndid you mean: ${nearest.join(", ")}?\nor run \`handoff list\` to see all\n`;
}

async function readStdin(): Promise<string> {
  let data = "";
  for await (const chunk of process.stdin) {
    data += chunk;
  }
  return data;
}

interface SaveArgs {
  slug: string;
  summary: string;
  parent?: string;
  force: boolean;
}

async function cmdSave(args: SaveArgs): Promise<void> {
  validateSlug(args.slug);
  if (args.parent !== undefined) validateSlug(args.parent);

  const content = await readStdin();
  if (content.length === 0) {
    process.stderr.write(
      "no content on stdin (pipe markdown content into save)\n",
    );
    process.exit(1);
  }

  const key = handoffKey(args.slug);
  if (!args.force) {
    const exists = (await upstashCall("EXISTS", key)) as number;
    if (exists === 1) {
      const existingSummary = (await upstashCall(
        "HGET",
        key,
        "summary",
      )) as string | null;
      process.stderr.write(
        `handoff "${args.slug}" already exists${
          existingSummary ? ` — ${existingSummary}` : ""
        }\nuse --force to overwrite\n`,
      );
      process.exit(1);
    }
  }

  const now = new Date().toISOString();
  const nowScore = Date.now();

  const hashFields: (string | number)[] = [
    "HSET",
    key,
    "content",
    content,
    "summary",
    args.summary,
    "created_at",
    now,
    "last_touched_at",
    now,
  ];
  if (args.parent !== undefined) {
    hashFields.push("parent", args.parent);
  }

  await upstashPipeline([
    hashFields,
    ["PEXPIRE", key, TTL_MS],
    ["ZADD", INDEX_KEY, nowScore, args.slug],
  ]);
}

async function cmdLoad(slug: string): Promise<void> {
  validateSlug(slug);
  const key = handoffKey(slug);
  const raw = await upstashCall("HGETALL", key);
  const fields = parseHashArray(raw);

  if (Object.keys(fields).length === 0) {
    const allSlugs = await listAllSlugs();
    const nearest = findNearestSlugs(slug, allSlugs);
    process.stderr.write(notFoundMessage(slug, nearest));
    process.exit(1);
  }

  const content = fields.content ?? "";
  const lastTouchedAt = fields.last_touched_at ?? "";
  const parent = fields.parent;

  const now = new Date().toISOString();
  const nowScore = Date.now();
  await upstashPipeline([
    ["HSET", key, "last_touched_at", now],
    ["PEXPIRE", key, TTL_MS],
    ["ZADD", INDEX_KEY, nowScore, slug],
  ]);

  const age = lastTouchedAt ? ageString(lastTouchedAt) : "unknown age";
  const parentClause = parent ? `parent: ${parent}` : "no parent";
  process.stderr.write(`loaded "${slug}" (${age}, ${parentClause})\n`);

  process.stdout.write(content);
}

async function cmdDelete(slug: string): Promise<void> {
  validateSlug(slug);
  const key = handoffKey(slug);
  const exists = (await upstashCall("EXISTS", key)) as number;
  if (exists === 0) {
    const allSlugs = await listAllSlugs();
    const nearest = findNearestSlugs(slug, allSlugs);
    process.stderr.write(notFoundMessage(slug, nearest));
    process.exit(1);
  }
  await upstashPipeline([
    ["DEL", key],
    ["ZREM", INDEX_KEY, slug],
  ]);
}

interface Entry {
  slug: string;
  summary: string;
  parent?: string;
  createdAt: string;
  lastTouchedAt: string;
  scoreMs: number;
}

async function fetchAllEntries(): Promise<{
  entries: Entry[];
  orphans: string[];
}> {
  const indexResult = (await upstashCall(
    "ZRANGE",
    INDEX_KEY,
    0,
    -1,
    "WITHSCORES",
  )) as string[] | null;
  if (!indexResult || indexResult.length === 0) {
    return { entries: [], orphans: [] };
  }
  const slugs: string[] = [];
  const scores: number[] = [];
  for (let i = 0; i < indexResult.length; i += 2) {
    slugs.push(indexResult[i]);
    scores.push(Number(indexResult[i + 1]));
  }
  const hashResults = await upstashPipeline(
    slugs.map((slug) => ["HGETALL", handoffKey(slug)]),
  );

  const entries: Entry[] = [];
  const orphans: string[] = [];
  for (let i = 0; i < slugs.length; i++) {
    const slug = slugs[i];
    const fields = parseHashArray(hashResults[i]);
    if (Object.keys(fields).length === 0) {
      orphans.push(slug);
      continue;
    }
    entries.push({
      slug,
      summary: fields.summary ?? "",
      parent: fields.parent,
      createdAt: fields.created_at ?? "",
      lastTouchedAt: fields.last_touched_at ?? "",
      scoreMs: scores[i],
    });
  }
  return { entries, orphans };
}

async function pruneOrphans(orphans: string[]): Promise<void> {
  if (orphans.length === 0) return;
  await upstashCall("ZREM", INDEX_KEY, ...orphans);
}

interface TreeNode {
  entry: Entry;
  children: TreeNode[];
  orphanedFrom?: string;
}

function buildTree(entries: Entry[]): TreeNode[] {
  const bySlug = new Map<string, Entry>();
  for (const e of entries) bySlug.set(e.slug, e);
  const childrenByParent = new Map<string, Entry[]>();
  const roots: Entry[] = [];
  const orphanedRoots: { entry: Entry; orphanedFrom: string }[] = [];

  for (const e of entries) {
    if (!e.parent) {
      roots.push(e);
    } else if (bySlug.has(e.parent)) {
      const arr = childrenByParent.get(e.parent) ?? [];
      arr.push(e);
      childrenByParent.set(e.parent, arr);
    } else {
      orphanedRoots.push({ entry: e, orphanedFrom: e.parent });
    }
  }

  function buildNode(e: Entry, orphanedFrom?: string): TreeNode {
    const kids = (childrenByParent.get(e.slug) ?? []).slice();
    kids.sort((a, b) => b.scoreMs - a.scoreMs);
    return {
      entry: e,
      orphanedFrom,
      children: kids.map((k) => buildNode(k)),
    };
  }

  const sortedRoots = roots
    .slice()
    .sort((a, b) => b.scoreMs - a.scoreMs)
    .map((e) => buildNode(e));
  const sortedOrphans = orphanedRoots
    .slice()
    .sort((a, b) => b.entry.scoreMs - a.entry.scoreMs)
    .map((o) => buildNode(o.entry, o.orphanedFrom));
  return [...sortedRoots, ...sortedOrphans];
}

function renderEntryLine(
  e: Entry,
  prefix: string,
  branch: string,
  orphanedFrom?: string,
): string {
  const age = ageString(e.scoreMs);
  const orphanSuffix = orphanedFrom ? ` ↳ from: ${orphanedFrom}` : "";
  return `${prefix}${branch}${e.slug} (${age})${orphanSuffix} — ${e.summary}`;
}

function renderChildren(
  children: TreeNode[],
  parentPrefix: string,
  lines: string[],
): void {
  for (let i = 0; i < children.length; i++) {
    const isLast = i === children.length - 1;
    const branch = isLast ? "└─ " : "├─ ";
    const child = children[i];
    lines.push(
      renderEntryLine(child.entry, parentPrefix, branch, child.orphanedFrom),
    );
    const childPrefix = parentPrefix + (isLast ? "   " : "│  ");
    renderChildren(child.children, childPrefix, lines);
  }
}

function renderTree(nodes: TreeNode[]): string {
  const lines: string[] = [];
  for (let i = 0; i < nodes.length; i++) {
    const node = nodes[i];
    lines.push(renderEntryLine(node.entry, "", "", node.orphanedFrom));
    renderChildren(node.children, "", lines);
    if (i < nodes.length - 1) lines.push("");
  }
  return lines.join("\n") + "\n";
}

async function cmdList(): Promise<void> {
  const { entries, orphans } = await fetchAllEntries();
  await pruneOrphans(orphans);
  if (entries.length === 0) {
    process.stdout.write(
      'no handoffs found. (use prose: "save a handoff for X" to create one)\n',
    );
    return;
  }
  const tree = buildTree(entries);
  process.stdout.write(renderTree(tree));
}

function inTmux(): boolean {
  return Boolean(process.env.TMUX);
}

async function tmuxRun(args: string[]): Promise<{
  stdout: string;
  stderr: string;
  exitCode: number;
}> {
  const proc = Bun.spawn(["tmux", ...args], {
    stdout: "pipe",
    stderr: "pipe",
  });
  const [stdout, stderr] = await Promise.all([
    new Response(proc.stdout).text(),
    new Response(proc.stderr).text(),
  ]);
  const exitCode = await proc.exited;
  return { stdout, stderr, exitCode };
}

async function tmuxListWindowNames(): Promise<string[]> {
  const { stdout, exitCode } = await tmuxRun([
    "list-windows",
    "-F",
    "#{window_name}",
  ]);
  if (exitCode !== 0) return [];
  return stdout.split("\n").filter((line) => line.length > 0);
}

async function tmuxNewWindow(name: string, command: string): Promise<string> {
  const { stdout, stderr, exitCode } = await tmuxRun([
    "new-window",
    "-P",
    "-F",
    "#{window_id}",
    "-n",
    name,
    command,
  ]);
  if (exitCode !== 0) {
    throw new Error(
      `tmux new-window failed (exit ${exitCode}): ${stderr.trim()}`,
    );
  }
  return stdout.trim();
}

async function tmuxSendKeys(target: string, keys: string): Promise<void> {
  const { stderr, exitCode } = await tmuxRun([
    "send-keys",
    "-t",
    target,
    keys,
    "Enter",
  ]);
  if (exitCode !== 0) {
    throw new Error(
      `tmux send-keys failed (exit ${exitCode}): ${stderr.trim()}`,
    );
  }
}

async function tmuxCapturePane(target: string): Promise<string> {
  const { stdout, exitCode } = await tmuxRun(["capture-pane", "-p", "-t", target]);
  if (exitCode !== 0) return "";
  return stdout;
}

async function waitForClaudeReady(target: string): Promise<void> {
  // Poll capture-pane up to 5s for a marker that indicates claude is awaiting input.
  // The marker is the bordered prompt char "│" preceded by ">" — Claude Code's
  // input-line styling. If absent after 5s, fall through to a fixed sleep.
  const deadline = Date.now() + 5000;
  while (Date.now() < deadline) {
    const pane = await tmuxCapturePane(target);
    if (/│\s*>\s/.test(pane) || /^>\s/m.test(pane)) return;
    await new Promise((r) => setTimeout(r, 100));
  }
  await new Promise((r) => setTimeout(r, 500));
}

function longestCommonPrefix(strs: string[]): string {
  if (strs.length === 0) return "";
  if (strs.length === 1) return strs[0];
  let prefix = strs[0];
  for (let i = 1; i < strs.length; i++) {
    while (!strs[i].startsWith(prefix)) {
      prefix = prefix.slice(0, -1);
      if (prefix === "") return "";
    }
  }
  return prefix;
}

function boundaryTrim(prefix: string): string {
  // Walk back to the previous separator (- or _) so we don't strip mid-word.
  // Returns prefix unchanged if it already ends at a boundary or is empty.
  if (prefix.length === 0) return prefix;
  if (prefix.endsWith("-") || prefix.endsWith("_")) return prefix;
  for (let i = prefix.length - 1; i >= 0; i--) {
    if (prefix[i] === "-" || prefix[i] === "_") {
      return prefix.slice(0, i + 1);
    }
  }
  return "";
}

function resolveWindowNames(
  slugs: string[],
  parentSlug: string | undefined,
  existingWindows: Set<string>,
): Map<string, string> {
  const result = new Map<string, string>();
  if (slugs.length === 0) return result;

  let stripPrefix: string;
  if (slugs.length === 1) {
    // N=1: no LCP across siblings; use parent slug as prefix if available.
    stripPrefix = parentSlug ? boundaryTrim(parentSlug + "-") : "";
    // Boundary-trim against the slug itself: if the slug doesn't actually start
    // with parent+sep, fall back to no strip.
    if (stripPrefix && !slugs[0].startsWith(stripPrefix)) stripPrefix = "";
  } else {
    stripPrefix = boundaryTrim(longestCommonPrefix(slugs));
  }

  const taken = new Set(existingWindows);
  for (const slug of slugs) {
    let name = stripPrefix && slug.startsWith(stripPrefix)
      ? slug.slice(stripPrefix.length)
      : slug;
    if (name.length === 0) name = slug; // empty-string guard
    if (taken.has(name)) name = slug; // collision: fall back to full slug
    if (taken.has(name)) {
      // Full slug also taken: append -2, -3, ...
      let n = 2;
      while (taken.has(`${name}-${n}`)) n++;
      name = `${name}-${n}`;
    }
    taken.add(name);
    result.set(slug, name);
  }
  return result;
}

interface SpawnArgs {
  slugs: string[];
  childrenOf?: string;
  dryRun: boolean;
}

function parseSpawnArgs(rest: string[]): SpawnArgs {
  const slugs: string[] = [];
  let childrenOf: string | undefined;
  let dryRun = false;
  let i = 0;
  while (i < rest.length) {
    const arg = rest[i];
    if (arg === "--children-of") {
      childrenOf = rest[i + 1];
      i += 2;
    } else if (arg === "--dry-run") {
      dryRun = true;
      i += 1;
    } else if (arg.startsWith("--")) {
      process.stderr.write(`unknown arg: ${arg}\n`);
      process.exit(1);
    } else {
      slugs.push(arg);
      i += 1;
    }
  }
  if (childrenOf !== undefined && slugs.length > 0) {
    process.stderr.write(
      "--children-of is mutually exclusive with positional slugs\n",
    );
    process.exit(1);
  }
  if (childrenOf === undefined && slugs.length === 0) {
    process.stderr.write(
      "usage: handoff spawn <slug>... | --children-of <parent-slug> [--dry-run]\n",
    );
    process.exit(1);
  }
  if (childrenOf !== undefined) validateSlug(childrenOf);
  for (const s of slugs) validateSlug(s);
  return { slugs, childrenOf, dryRun };
}

async function resolveSpawnSlugs(args: SpawnArgs): Promise<{
  slugs: string[];
  parentSlug: string | undefined;
}> {
  let candidateSlugs: string[];
  let parentSlug: string | undefined;

  if (args.childrenOf !== undefined) {
    parentSlug = args.childrenOf;
    const { entries } = await fetchAllEntries();
    const children = entries
      .filter((e) => e.parent === args.childrenOf)
      .sort((a, b) => b.scoreMs - a.scoreMs);
    if (children.length === 0) {
      process.stderr.write(
        `no children found for parent "${args.childrenOf}"\n`,
      );
      process.exit(1);
    }
    candidateSlugs = children.map((e) => e.slug);
  } else {
    candidateSlugs = args.slugs;
    // Try to infer parent: if all explicit slugs share the same parent in the
    // index, use it. Otherwise undefined.
    const { entries } = await fetchAllEntries();
    const bySlug = new Map(entries.map((e) => [e.slug, e]));
    const parents = new Set<string | undefined>();
    for (const s of candidateSlugs) {
      const e = bySlug.get(s);
      parents.add(e?.parent);
    }
    if (parents.size === 1) {
      const only = parents.values().next().value;
      if (only !== undefined) parentSlug = only;
    }
  }

  // Validate existence; drop missing.
  const surviving: string[] = [];
  for (const slug of candidateSlugs) {
    const exists = (await upstashCall("EXISTS", handoffKey(slug))) as number;
    if (exists === 1) {
      surviving.push(slug);
    } else {
      process.stderr.write(`no such handoff "${slug}", skipping\n`);
    }
  }
  if (surviving.length === 0) {
    process.stderr.write("no slugs to spawn\n");
    process.exit(1);
  }
  return { slugs: surviving, parentSlug };
}

async function cmdSpawn(args: SpawnArgs): Promise<void> {
  const { slugs, parentSlug } = await resolveSpawnSlugs(args);
  const existingWindows = inTmux()
    ? new Set(await tmuxListWindowNames())
    : new Set<string>();
  const names = resolveWindowNames(slugs, parentSlug, existingWindows);

  if (args.dryRun || !inTmux()) {
    for (const slug of slugs) {
      const name = names.get(slug)!;
      const safeSlug = slug.replace(/'/g, "'\\''");
      process.stdout.write(
        `tmux new-window -P -F '#{window_id}' -n ${name} 'claude'\n`,
      );
      process.stdout.write(
        `tmux send-keys -t <WID> '/handoff load ${safeSlug}' Enter\n`,
      );
    }
    return;
  }

  let anyHardFailure = false;
  for (const slug of slugs) {
    const name = names.get(slug)!;
    let wid: string;
    try {
      wid = await tmuxNewWindow(name, "claude");
    } catch (e) {
      process.stderr.write(`failed to spawn window for "${slug}": ${(e as Error).message}\n`);
      anyHardFailure = true;
      continue;
    }
    try {
      await waitForClaudeReady(wid);
      await tmuxSendKeys(wid, `/handoff load ${slug}`);
    } catch (e) {
      process.stderr.write(
        `window ${wid} ("${name}") created but send-keys failed for "${slug}": ${(e as Error).message}\n`,
      );
      // Window stays; user can manually send-keys. Do not flip exit code.
      continue;
    }
    process.stdout.write(`spawned ${name} → window ${wid} (slug: ${slug})\n`);
  }
  if (anyHardFailure) process.exit(2);
}

function parseSaveArgs(rest: string[]): SaveArgs {
  if (rest.length === 0) {
    process.stderr.write(
      'usage: handoff save <slug> --summary "<one-line>" [--parent <slug>] [--force]\n',
    );
    process.exit(1);
  }
  const slug = rest[0];
  let summary: string | undefined;
  let parent: string | undefined;
  let force = false;
  let i = 1;
  while (i < rest.length) {
    const arg = rest[i];
    if (arg === "--summary") {
      summary = rest[i + 1];
      i += 2;
    } else if (arg === "--parent") {
      parent = rest[i + 1];
      i += 2;
    } else if (arg === "--force") {
      force = true;
      i += 1;
    } else {
      process.stderr.write(`unknown arg: ${arg}\n`);
      process.exit(1);
    }
  }
  if (summary === undefined) {
    process.stderr.write("missing required --summary\n");
    process.exit(1);
  }
  if (summary.length > 120) {
    process.stderr.write(`summary too long (${summary.length} > 120 chars)\n`);
    process.exit(1);
  }
  return { slug, summary, parent, force };
}

async function main(argv: string[]): Promise<void> {
  if (argv[2] === "--self-test") {
    selfTest();
    return;
  }
  const verb = argv[2];
  const rest = argv.slice(3);
  switch (verb) {
    case "save":
      await cmdSave(parseSaveArgs(rest));
      return;
    case "load": {
      const slug = rest[0];
      if (!slug) {
        process.stderr.write("usage: handoff load <slug>\n");
        process.exit(1);
      }
      await cmdLoad(slug);
      return;
    }
    case "delete": {
      const slug = rest[0];
      if (!slug) {
        process.stderr.write("usage: handoff delete <slug>\n");
        process.exit(1);
      }
      await cmdDelete(slug);
      return;
    }
    case "list":
      await cmdList();
      return;
    case "spawn":
      await cmdSpawn(parseSpawnArgs(rest));
      return;
    default:
      process.stderr.write(
        "usage: handoff <save|load|list|delete|spawn> [args...]\n",
      );
      process.exit(1);
  }
}

function selfTest(): void {
  function eq<T>(label: string, got: T, want: T): void {
    const ok = JSON.stringify(got) === JSON.stringify(want);
    if (!ok) {
      process.stderr.write(`FAIL ${label}\n  got:  ${JSON.stringify(got)}\n  want: ${JSON.stringify(want)}\n`);
      process.exit(1);
    }
  }

  eq("LCP empty list", longestCommonPrefix([]), "");
  eq("LCP single", longestCommonPrefix(["foo-bar"]), "foo-bar");
  eq("LCP shared", longestCommonPrefix(["sdf-store-a", "sdf-store-b"]), "sdf-store-");
  eq("LCP partial", longestCommonPrefix(["sdf-store-mu", "sdf-store-multi"]), "sdf-store-mu");
  eq("LCP none", longestCommonPrefix(["foo", "bar"]), "");

  eq("trim already at boundary", boundaryTrim("sdf-store-"), "sdf-store-");
  eq("trim mid-word", boundaryTrim("sdf-store-mu"), "sdf-store-");
  eq("trim no boundary", boundaryTrim("foobar"), "");
  eq("trim empty", boundaryTrim(""), "");

  const empty = new Set<string>();
  eq(
    "resolve siblings",
    Array.from(resolveWindowNames(
      ["sdf-store-multistep-horizon", "sdf-store-rolling-share-baseline", "sdf-store-lag1-attribution"],
      "sdf-store-dept-extension",
      empty,
    ).entries()),
    [
      ["sdf-store-multistep-horizon", "multistep-horizon"],
      ["sdf-store-rolling-share-baseline", "rolling-share-baseline"],
      ["sdf-store-lag1-attribution", "lag1-attribution"],
    ],
  );

  eq(
    "resolve N=1 with parent",
    Array.from(resolveWindowNames(
      ["encoder-warmerdam"],
      "encoder-camps-overview",
      empty,
    ).entries()),
    [["encoder-warmerdam", "encoder-warmerdam"]],
    // parent prefix "encoder-camps-overview-" is not a prefix of "encoder-warmerdam",
    // so falls back to full slug.
  );

  eq(
    "resolve N=1 with parent that IS a prefix",
    Array.from(resolveWindowNames(
      ["encoder-warmerdam"],
      "encoder",
      empty,
    ).entries()),
    [["encoder-warmerdam", "warmerdam"]],
  );

  eq(
    "resolve unrelated slugs",
    Array.from(resolveWindowNames(["foo-bar", "baz-qux"], undefined, empty).entries()),
    [["foo-bar", "foo-bar"], ["baz-qux", "baz-qux"]],
  );

  eq(
    "resolve with existing window collision",
    Array.from(resolveWindowNames(
      ["sdf-store-a", "sdf-store-b"],
      undefined,
      new Set(["a"]),
    ).entries()),
    [["sdf-store-a", "sdf-store-a"], ["sdf-store-b", "b"]],
  );

  eq(
    "resolve with full-slug collision and dedup",
    Array.from(resolveWindowNames(
      ["sdf-store-a"],
      undefined,
      new Set(["a", "sdf-store-a"]),
    ).entries()),
    [["sdf-store-a", "sdf-store-a-2"]],
  );

  process.stdout.write("self-test ok\n");
}

main(process.argv).catch((e: Error) => {
  if (e instanceof UpstashError) {
    process.stderr.write(`${e.message}\n`);
    process.exit(2);
  }
  process.stderr.write(`${e.message}\n`);
  process.exit(1);
});
