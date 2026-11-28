import { createServer } from "node:http";
import { mkdir, mkdtemp, readFile, rm, stat, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { extname, join, normalize } from "node:path";
import { fileURLToPath } from "node:url";
import { execFile } from "node:child_process";
import { promisify } from "node:util";

const run = promisify(execFile);
const root = fileURLToPath(new URL("..", import.meta.url));
const port = Number(process.env.PORT ?? 4318);
const work = await mkdtemp(join(tmpdir(), "dotmind-media-"));
const types = { ".html": "text/html; charset=utf-8", ".js": "text/javascript; charset=utf-8", ".map": "application/json" };

async function body(req) {
  const chunks = [];
  for await (const c of req) chunks.push(c);
  return Buffer.concat(chunks);
}

async function encode(name, frames, fps) {
  const dir = join(work, name);
  const out = join(root, "docs", `${name}.gif`);
  const filter = "split[a][b];[a]palettegen=max_colors=192:stats_mode=full:reserve_transparent=0[p];[b][p]paletteuse=dither=sierra2_4a:diff_mode=rectangle";
  await run("ffmpeg", ["-y", "-loglevel", "error", "-framerate", String(fps), "-i", join(dir, "%04d.png"), "-frames:v", String(frames), "-vf", filter, "-loop", "0", out]);
  const { size } = await stat(out);
  console.log(`${name}.gif ${frames} frames ${(size / 1024 / 1024).toFixed(2)} MB`);
  await rm(dir, { recursive: true, force: true });
}

createServer(async (req, res) => {
  const url = new URL(req.url ?? "/", "http://x");
  const name = url.searchParams.get("name") ?? "";
  if (req.method === "POST" && !/^[a-z]+$/.test(name)) {
    res.writeHead(400).end();
    return;
  }
  if (req.method === "POST" && url.pathname === "/frame") {
    const dir = join(work, name);
    await mkdir(dir, { recursive: true });
    const i = Number(url.searchParams.get("i"));
    await writeFile(join(dir, `${String(i).padStart(4, "0")}.png`), await body(req));
    res.writeHead(204).end();
    return;
  }
  if (req.method === "POST" && url.pathname === "/done") {
    await encode(name, Number(url.searchParams.get("frames")), Number(url.searchParams.get("fps")));
    res.writeHead(204).end();
    return;
  }
  const path = decodeURIComponent(url.pathname);
  const rel = path.endsWith("/") ? `${path.slice(1)}index.html` : path.slice(1);
  const file = normalize(join(root, rel));
  if (!file.startsWith(root)) {
    res.writeHead(403).end();
    return;
  }
  try {
    const data = await readFile(file);
    res.writeHead(200, { "content-type": types[extname(file)] ?? "application/octet-stream", "cache-control": "no-store" });
    res.end(data);
  } catch {
    res.writeHead(404).end("not found");
  }
}).listen(port, "127.0.0.1", () => console.log(`open http://127.0.0.1:${port}/scripts/media/ to render docs/*.gif`));
