const { test, describe, before, after } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');
const Store = require('../src/main/store');

function makeTempDir() {
  return fs.mkdtempSync(path.join(os.tmpdir(), 'nook-test-'));
}

describe('Store: basic CRUD', () => {
  let dir, store;
  before(() => { dir = makeTempDir(); store = new Store(dir); });
  after(() => { fs.rmSync(dir, { recursive: true, force: true }); });

  test('initial state is empty', () => {
    assert.equal(store.getTasks().length, 0);
    assert.deepEqual(store.getAllTags(), {});
    assert.equal(store.getSnippets().length, 0);
  });

  test('addTask persists fields', () => {
    const t = store.addTask('写测试', 'high', ['dev', 'testing'], '2026-04-18');
    assert.equal(t.title, '写测试');
    assert.equal(t.priority, 'high');
    assert.deepEqual(t.tags, ['dev', 'testing']);
    assert.equal(t.dueDate, '2026-04-18');
    assert.equal(t.completed, false);
  });

  test('global tag list auto-syncs from new task tags', () => {
    assert.ok('dev' in store.getAllTags());
    assert.ok('testing' in store.getAllTags());
  });

  test('toggleTask flips completed state', () => {
    const [t] = store.getTasks();
    store.toggleTask(t.id);
    assert.equal(store.getTask(t.id).completed, true);
    assert.ok(store.getTask(t.id).completedAt);
    store.toggleTask(t.id);
    assert.equal(store.getTask(t.id).completed, false);
  });

  test('subtasks CRUD', () => {
    const [t] = store.getTasks();
    const s = store.addSubtask(t.id, '子步骤 1');
    assert.equal(s.title, '子步骤 1');
    assert.equal(store.getTask(t.id).subtasks.length, 1);
    store.toggleSubtask(t.id, s.id);
    assert.equal(store.getTask(t.id).subtasks[0].completed, true);
    store.deleteSubtask(t.id, s.id);
    assert.equal(store.getTask(t.id).subtasks.length, 0);
  });

  test('setTagColor stores custom color', () => {
    store.setTagColor('dev', '#FF9A14');
    assert.equal(store.getAllTags().dev.color, '#FF9A14');
  });

  test('snippets CRUD + password type', () => {
    const s = store.addSnippet('SSH server', 'ssh dev@host', 'password');
    assert.equal(s.type, 'password');
    assert.equal(store.getSnippets().length, 1);
    store.updateSnippet(s.id, { value: 'ssh prod@host' });
    assert.equal(store.getSnippets()[0].value, 'ssh prod@host');
    store.deleteSnippet(s.id);
    assert.equal(store.getSnippets().length, 0);
  });

  test('settings default + update', () => {
    assert.equal(store.getSettings().cornerTrigger, 'top-left');
    store.updateSettings({ cornerTrigger: 'bottom-right' });
    assert.equal(store.getSettings().cornerTrigger, 'bottom-right');
  });

  test('data persists across instances', () => {
    const dir2 = dir;
    const reopened = new Store(dir2);
    assert.equal(reopened.getSettings().cornerTrigger, 'bottom-right');
    assert.equal(reopened.getTasks()[0].title, '写测试');
  });
});

describe('Store: schema migration from legacy formats', () => {
  test('tags Array is upgraded to { name: { color } } object', () => {
    const dir = makeTempDir();
    const file = path.join(dir, 'tasks.json');
    fs.writeFileSync(file, JSON.stringify({
      tasks: [{ id: 1, title: 'old', tags: ['urgent'], priority: 'high' }],
      tags: ['urgent', 'work'],
      nextId: 2,
    }));

    const store = new Store(dir);
    const tags = store.getAllTags();
    assert.ok('urgent' in tags && 'work' in tags);
    assert.equal(tags.urgent.color, null);
    fs.rmSync(dir, { recursive: true, force: true });
  });

  test('missing fields get sensible defaults on legacy tasks', () => {
    const dir = makeTempDir();
    fs.writeFileSync(path.join(dir, 'tasks.json'), JSON.stringify({
      tasks: [{ id: 1, title: 'legacy' }],
      nextId: 2,
    }));

    const store = new Store(dir);
    const t = store.getTask(1);
    assert.equal(t.priority, 'none');
    assert.deepEqual(t.tags, []);
    assert.deepEqual(t.subtasks, []);
    assert.equal(t.dueDate, null);
    fs.rmSync(dir, { recursive: true, force: true });
  });
});
