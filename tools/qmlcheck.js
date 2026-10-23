// Static sanity checker for the Quickshell config (no QML toolchain available offline).
const fs = require('fs'), path = require('path');
const root = process.argv[2];
const files = [];
(function walk(d) { for (const f of fs.readdirSync(d)) { const p = path.join(d, f); fs.statSync(p).isDirectory() ? walk(p) : p.endsWith('.qml') && files.push(p); } })(root);

const known = new Set(`Item Rectangle Text Image MouseArea Repeater ListView Flickable Timer Behavior NumberAnimation ColorAnimation SequentialAnimation
Component QtObject Connections Translate TextInput WheelHandler Loader Row Column Grid Transition
RowLayout ColumnLayout GridLayout StackLayout Shape ShapePath PathAngleArc MultiEffect
Singleton ShellRoot Scope Variants PanelWindow Region QsMenuAnchor SystemClock ShellScreen
FileView JsonAdapter JsonObject Process StdioCollector IpcHandler HyprlandFocusGrab HyprlandMonitor
WlSessionLock WlSessionLockSurface IdleMonitor PamContext NotificationServer PwObjectTracker PwNode SystemTrayItem
IconImage ClippingRectangle Notification MprisPlayer Window`.split(/\s+/));

const strip = s => s.replace(/"(?:[^"\\\n]|\\.)*"/g, '""').replace(/'(?:[^'\\\n]|\\.)*'/g, "''")
  .replace(/\/\*[\s\S]*?\*\//g, m => m.replace(/[^\n]/g, ' '))
  .replace(/\/\/.*$/gm, '');

// ── collect module members ────────────────────────────────────────
const dirTypes = {}; // dir -> Set(type names)
for (const f of files) { const d = path.dirname(f); (dirTypes[d] ||= new Set()).add(path.basename(f, '.qml')); }
const singletons = {}; // name -> {members:Set, file, dir}
for (const f of files) {
  const raw = fs.readFileSync(f, 'utf8');
  if (!/^\s*pragma Singleton/m.test(raw)) continue;
  const name = path.basename(f, '.qml'); const s = strip(raw); const m = new Set();
  for (const r of s.matchAll(/\b(?:readonly\s+)?property\s+(?:alias\s+)?[\w.<>]+\s+(\w+)/g)) m.add(r[1]);
  for (const r of s.matchAll(/\bfunction\s+(\w+)/g)) m.add(r[1]);
  for (const r of s.matchAll(/\bsignal\s+(\w+)/g)) m.add(r[1]);
  for (const r of s.matchAll(/\bid:\s*(\w+)/g)) m.add('#id:' + r[1]);
  // signals for each property: onXChanged handled elsewhere
  singletons[name] = { m, file: f, dir: path.dirname(f) };
}
const modDir = imp => { // "qs.modules.bar" -> <root>/modules/bar
  const rel = imp.replace(/^qs\.?/, '').split('.').filter(Boolean); return path.join(root, ...rel); };

let errors = 0; const err = (f, msg) => { errors++; console.log(path.relative(root, f) + ': ' + msg); };

for (const f of files) {
  const raw = fs.readFileSync(f, 'utf8'); const s = strip(raw); const dir = path.dirname(f);
  // brace balance
  let depth = 0, line = 1, paren = 0, brack = 0;
  for (const ch of s) { if (ch === '\n') line++; if (ch === '{') depth++; if (ch === '}') depth--; if (ch === '(') paren++; if (ch === ')') paren--; if (ch === '[') brack++; if (ch === ']') brack--; if (depth < 0) { err(f, 'unbalanced } near line ' + line); depth = 0; } }
  if (depth !== 0) err(f, 'unbalanced braces (' + depth + ')');
  if (paren !== 0) err(f, 'unbalanced parens (' + paren + ')');
  if (brack !== 0) err(f, 'unbalanced brackets (' + brack + ')');

  // imports
  const imports = [...s.matchAll(/^\s*import\s+([\w.]+)/gm)].map(r => r[1]);
  const visible = new Set(dirTypes[dir] || []);
  for (const i of imports) {
    if (i.startsWith('qs')) { const d = modDir(i); if (!fs.existsSync(d)) err(f, 'import ' + i + ' -> missing directory'); else (dirTypes[d] || []).forEach(t => visible.add(t)); }
  }
  const inline = new Set([...s.matchAll(/\bcomponent\s+(\w+)\s*:/g)].map(r => r[1]));
  // element instantiations
  for (const r of s.matchAll(/(?:^|[\s:;{])([A-Z]\w*)(?:\.\w+)*\s*\{/gm)) {
    const t = r[1];
    if (known.has(t) || visible.has(t) || inline.has(t)) continue;
    if (/^(?:Easing|Qt)$/.test(t)) continue;
    err(f, 'unresolved type ' + t);
  }
  // singleton use
  const here = path.basename(f, '.qml');
  for (const [n, info] of Object.entries(singletons)) {
    if (n === here) continue;
    const re = new RegExp('(?<![\\w.])' + n + '\\.(\\w+)', 'g');
    let used = false;
    for (const r of s.matchAll(re)) {
      used = true;
      if (!info.m.has(r[1])) err(f, `${n}.${r[1]} is not a member of ${n}`);
    }
    if (used && !(visible.has(n))) err(f, `uses ${n} without importing its module`);
  }
  // unknown singleton-like usage in own file: required id references
  const ids = new Set([...s.matchAll(/\bid:\s*(\w+)/g)].map(r => r[1]));
  for (const r of s.matchAll(/(?<![\w.])(\w+)\.(?:visible|width|height|implicitWidth|implicitHeight|x|y|text|currentIndex|contentHeight|count|activeFocus|running|forceActiveFocus|restart|start)\b/g)) {
    const n = r[1];
    if (/^[a-z]/.test(n) && !ids.has(n) && !['root','parent','this','event','modelData','Qt','Math','JSON','console','Date','Object','Array','String','Number','item','wheel','mouse','text','width','height'].includes(n)) {
      // could be a property/param; only flag obvious id-like usage
      if (/^(list|row|col|card|pill|content|layout|search|input|pass|fade|shake|hide|clip|stat|meminfo|diskProc|proc|scan|keys|field|art|face|grid|thumb|cell|item|slot|button|menu|track|fill|wall|ind)$/.test(n)) err(f, `reference to id '${n}' not declared in this file`);
    }
  }
}
console.log(errors ? `\n${errors} problem(s)` : `OK: ${files.length} QML files, no problems found`);
process.exit(errors ? 1 : 0);
