import { existsSync, readdirSync, readFileSync, statSync } from "node:fs";
import { join } from "node:path";

const projectRoot = new URL("../", import.meta.url).pathname;
const distDir = join(projectRoot, "dist");
const webJsDir = join(distDir, "_expo", "static", "js", "web");
const indexHtmlPath = join(distDir, "index.html");

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

assert(existsSync(distDir), "Missing dist output. Run the web export before verification.");
assert(existsSync(indexHtmlPath), "Missing dist/index.html.");
assert(existsSync(webJsDir), "Missing exported web JavaScript bundle directory.");

const indexHtml = readFileSync(indexHtmlPath, "utf8");
assert(indexHtml.includes('<div id="root"></div>'), "Exported index.html is missing the root container.");

const bundleFiles = readdirSync(webJsDir).filter((file) => file.endsWith(".js"));
assert(bundleFiles.length > 0, "No web JavaScript bundles were exported.");

for (const file of bundleFiles) {
  const fullPath = join(webJsDir, file);
  const content = readFileSync(fullPath, "utf8");

  assert(statSync(fullPath).size > 0, `Bundle ${file} is empty.`);
  assert(!content.includes("import.meta"), `Bundle ${file} still contains import.meta and will white-screen in production.`);
}

console.log(`Verified ${bundleFiles.length} web bundles in dist.`);
