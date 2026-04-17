const fs = require('fs');
const path = require('path');

class Store {
  constructor(dataPath) {
    this.filePath = path.join(dataPath, 'tasks.json');
    this.data = this._load();
    this._migrate();
  }

  /** 尝试从旧路径迁移数据到新路径。支持多个候选来源，picks newest. */
  static migrateFromLegacy(legacyCandidates, newPath) {
    const newFile = path.join(newPath, 'tasks.json');
    const candidates = Array.isArray(legacyCandidates) ? legacyCandidates : [legacyCandidates];
    try {
      if (fs.existsSync(newFile)) return; // already migrated
      // pick the newest legacy file that exists
      let bestSrc = null;
      let bestMtime = 0;
      for (const c of candidates) {
        const f = path.join(c, 'tasks.json');
        if (fs.existsSync(f)) {
          const m = fs.statSync(f).mtimeMs;
          if (m > bestMtime) { bestMtime = m; bestSrc = f; }
        }
      }
      if (bestSrc) {
        if (!fs.existsSync(newPath)) fs.mkdirSync(newPath, { recursive: true });
        fs.copyFileSync(bestSrc, newFile);
        console.log('[Store] Migrated data from', bestSrc, 'to', newFile);
      }
    } catch (e) {
      console.error('[Store] Migration failed:', e);
    }
  }

  _load() {
    try {
      if (fs.existsSync(this.filePath)) {
        const raw = fs.readFileSync(this.filePath, 'utf-8');
        return JSON.parse(raw);
      }
    } catch (e) {
      console.error('[Store] Failed to load:', e);
    }
    return {
      tasks: [], nextId: 1,
      tags: {}, snippets: [], nextSnippetId: 1,
      settings: { cornerTrigger: 'top-left' },
    };
  }

  _migrate() {
    let changed = false;
    // tags: Array → Object { name: { color } }
    if (Array.isArray(this.data.tags)) {
      const obj = {};
      for (const t of this.data.tags) {
        obj[t] = { color: null };
      }
      this.data.tags = obj;
      changed = true;
    }
    if (!this.data.tags) { this.data.tags = {}; changed = true; }
    if (!this.data.snippets) { this.data.snippets = []; changed = true; }
    if (!this.data.nextSnippetId) { this.data.nextSnippetId = 1; changed = true; }
    if (!this.data.settings) { this.data.settings = {}; changed = true; }
    if (!this.data.settings.cornerTrigger) { this.data.settings.cornerTrigger = 'top-left'; changed = true; }

    for (const task of this.data.tasks) {
      if (!task.priority) { task.priority = 'none'; changed = true; }
      if (!task.listId) { task.listId = 'inbox'; changed = true; }
      if (!task.description && task.description !== '') { task.description = ''; changed = true; }
      if (!task.tags) { task.tags = []; changed = true; }
      if (!task.subtasks) { task.subtasks = []; changed = true; }
      if (task.dueDate === undefined) { task.dueDate = null; changed = true; }
      if (!task.nextSubId) { task.nextSubId = 1; changed = true; }
    }
    if (changed) this._save();
  }

  _save() {
    const dir = path.dirname(this.filePath);
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    fs.writeFileSync(this.filePath, JSON.stringify(this.data, null, 2), 'utf-8');
  }

  getDataPath() {
    return this.filePath;
  }

  // ======= Tasks =======

  getTasks() {
    return this.data.tasks;
  }

  getTask(id) {
    return this.data.tasks.find(t => t.id === id) || null;
  }

  addTask(title, priority = 'none', tags = [], dueDate = null) {
    const task = {
      id: this.data.nextId++,
      title: title.trim(),
      description: '',
      completed: false,
      priority,
      tags,
      subtasks: [],
      nextSubId: 1,
      dueDate,
      listId: 'inbox',
      createdAt: new Date().toISOString(),
      completedAt: null,
    };
    this.data.tasks.unshift(task);
    this._syncGlobalTags(tags);
    this._save();
    return task;
  }

  toggleTask(id) {
    const task = this.data.tasks.find(t => t.id === id);
    if (task) {
      task.completed = !task.completed;
      task.completedAt = task.completed ? new Date().toISOString() : null;
      this._save();
    }
    return task;
  }

  deleteTask(id) {
    this.data.tasks = this.data.tasks.filter(t => t.id !== id);
    this._save();
  }

  updateTask(id, updates) {
    const task = this.data.tasks.find(t => t.id === id);
    if (task) {
      if (updates.tags) this._syncGlobalTags(updates.tags);
      Object.assign(task, updates);
      this._save();
    }
    return task;
  }

  clearCompleted() {
    this.data.tasks = this.data.tasks.filter(t => !t.completed);
    this._save();
  }

  // ======= Subtasks =======

  addSubtask(taskId, title) {
    const task = this.data.tasks.find(t => t.id === taskId);
    if (!task) return null;
    const sub = {
      id: task.nextSubId++,
      title: title.trim(),
      completed: false,
    };
    task.subtasks.push(sub);
    this._save();
    return sub;
  }

  toggleSubtask(taskId, subId) {
    const task = this.data.tasks.find(t => t.id === taskId);
    if (!task) return null;
    const sub = task.subtasks.find(s => s.id === subId);
    if (sub) {
      sub.completed = !sub.completed;
      this._save();
    }
    return task;
  }

  deleteSubtask(taskId, subId) {
    const task = this.data.tasks.find(t => t.id === taskId);
    if (!task) return null;
    task.subtasks = task.subtasks.filter(s => s.id !== subId);
    this._save();
    return task;
  }

  updateSubtask(taskId, subId, title) {
    const task = this.data.tasks.find(t => t.id === taskId);
    if (!task) return null;
    const sub = task.subtasks.find(s => s.id === subId);
    if (sub) {
      sub.title = title.trim();
      this._save();
    }
    return task;
  }

  // ======= Tags (Object: { tagName: { color } }) =======

  getAllTags() {
    return this.data.tags;
  }

  setTagColor(tagName, color) {
    if (!this.data.tags[tagName]) {
      this.data.tags[tagName] = { color };
    } else {
      this.data.tags[tagName].color = color;
    }
    this._save();
    return this.data.tags;
  }

  _syncGlobalTags(tags) {
    for (const tag of tags) {
      if (!this.data.tags[tag]) {
        this.data.tags[tag] = { color: null };
      }
    }
  }

  deleteTag(tagName) {
    delete this.data.tags[tagName];
    for (const task of this.data.tasks) {
      task.tags = task.tags.filter(t => t !== tagName);
    }
    this._save();
  }

  // ======= Snippets (快捷粘贴) =======

  getSnippets() {
    return this.data.snippets;
  }

  addSnippet(label, value, type = 'text') {
    const s = {
      id: this.data.nextSnippetId++,
      label: (label || '').trim(),
      value: value || '',
      type, // 'text' | 'password'
      createdAt: new Date().toISOString(),
    };
    this.data.snippets.push(s);
    this._save();
    return s;
  }

  updateSnippet(id, updates) {
    const s = this.data.snippets.find(x => x.id === id);
    if (s) {
      Object.assign(s, updates);
      this._save();
    }
    return s;
  }

  deleteSnippet(id) {
    this.data.snippets = this.data.snippets.filter(s => s.id !== id);
    this._save();
  }

  reorderSnippet(id, targetIndex) {
    const idx = this.data.snippets.findIndex(s => s.id === id);
    if (idx === -1) return;
    const [s] = this.data.snippets.splice(idx, 1);
    this.data.snippets.splice(targetIndex, 0, s);
    this._save();
  }

  // ======= Settings =======

  getSettings() {
    return this.data.settings;
  }

  updateSettings(updates) {
    Object.assign(this.data.settings, updates);
    this._save();
    return this.data.settings;
  }
}

module.exports = Store;
