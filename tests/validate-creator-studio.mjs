import fs from 'node:fs';
import vm from 'node:vm';
import assert from 'node:assert/strict';

const html = fs.readFileSync('geffenweverse-web-2026-11-14.html', 'utf8');
const studio = fs.readFileSync('creator-studio.js', 'utf8');
const migrations = [
  'supabase/migrations/20261123150152_creator_studio_analytics_foundation.sql',
  'supabase/migrations/20261123150623_creator_analytics_respect_selected_period.sql',
  'supabase/migrations/20261123150756_isolate_creator_analytics_definer_rpc.sql',
  'supabase/migrations/20261123152000_enforce_creator_and_engagement_rls.sql'
];

const inlineScripts = html.split('<script').slice(1)
  .map(part => part.slice(part.indexOf('>') + 1, part.indexOf('</script>')))
  .filter(source => source.trim());
assert.ok(inlineScripts.length >= 1, 'Expected inline application scripts');
inlineScripts.forEach((source, index) => new vm.Script(source, { filename: `inline-${index + 1}.js` }));
new vm.Script(studio, { filename: 'creator-studio.js' });

assert.ok(html.includes('<script src="./creator-studio.js"></script>'), 'Creator Studio script must load');
const externalScriptIndex = html.indexOf('<script src="./creator-studio.js"></script>');
assert.ok(externalScriptIndex > html.lastIndexOf('</script>', externalScriptIndex), 'Creator Studio script must load after app globals and handlers');
assert.ok(html.includes('"creator-studio": () => window.gwCreatorStudioPage'), 'Creator Studio route must be registered');
assert.ok(html.includes('shorts: () => window.gwShortsPage'), 'Shorts route must be registered');
assert.ok(html.includes("if(r==='creator-studio')gwLoadStudio()"), 'Creator Studio route loader must be connected');
assert.ok(html.includes("if(r==='shorts'&&typeof window.gwLoadShorts==='function')"), 'Shorts route loader must be connected');

for (const marker of [
  'function gwCreatorStudioPage()', 'function gwLoadStudio()', 'function gwShortsPage()',
  'function gwLoadShorts()', 'function gwToggleShortStar(', 'gw-cs-create-form',
  'data-cs-export', 'gw-short-upload-form', 'gw-short-comment', 'data-gw-short-star',
  "rpc('get_creator_analytics'"
]) assert.ok(studio.includes(marker), `Missing Creator Studio integration: ${marker}`);

for (const path of migrations) assert.ok(fs.existsSync(path), `Missing migration: ${path}`);

const analyticsMigration = fs.readFileSync(migrations[0], 'utf8');
const isolationMigration = fs.readFileSync(migrations[2], 'utf8');
const rlsMigration = fs.readFileSync(migrations[3], 'utf8');
assert.ok(analyticsMigration.includes('enable row level security'), 'Creator events must have RLS');
assert.ok(isolationMigration.includes('security invoker'), 'Public analytics RPC must use SECURITY INVOKER');
assert.ok(isolationMigration.includes('set schema private'), 'Definer implementation must be isolated');
for (const policy of ['shorts_enforce_creator_and_moderation','comments_enforce_author_and_moderation','starlights_enforce_owner_and_moderation','creator_events_no_self_view']) {
  assert.ok(rlsMigration.includes(policy), `Missing restrictive policy: ${policy}`);
}

console.log(`Creator Studio validation passed: ${inlineScripts.length} inline scripts, external script, route wiring, handlers and ${migrations.length} migrations.`);
