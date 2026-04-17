const { app, BrowserWindow, screen, ipcMain, globalShortcut } = require('electron');
const path = require('path');
const Store = require('./store');

let panelWindow = null;
let store = null;
let mousePoller = null;
let isPanelVisible = false;

const TRIGGER_SIZE = 8;
const PANEL_WIDTH = 380;
const POLL_INTERVAL = 100;

/**
 * Compute panel bounds + trigger zone given current display + user's chosen corner.
 *
 * corner: 'top-left' | 'top-right' | 'bottom-left' | 'bottom-right'
 *
 * Returns:
 *   - bounds: { x, y, width, height } — where to place the (full-height) window
 *   - triggerMin / triggerMax: rectangle in screen coords that summons the panel
 *   - side: 'left' | 'right' — which edge the panel slides in from (for CSS)
 */
function computeLayout(corner) {
  const d = screen.getPrimaryDisplay();
  const work = d.workArea;               // excludes menu bar / Dock
  const full = d.bounds;                 // entire screen

  const side = corner.endsWith('-right') ? 'right' : 'left';
  const vertical = corner.startsWith('top') ? 'top' : 'bottom';

  const bounds = {
    x: side === 'left' ? work.x : work.x + work.width - PANEL_WIDTH,
    y: work.y,
    width: PANEL_WIDTH,
    height: work.height,
  };

  // Trigger zone: the screen corner, extended a bit into workArea so Dock / menu bar don't block it.
  let triggerMin, triggerMax;
  if (corner === 'top-left') {
    triggerMin = { x: 0, y: 0 };
    triggerMax = { x: work.x + TRIGGER_SIZE, y: work.y + TRIGGER_SIZE };
  } else if (corner === 'top-right') {
    triggerMin = { x: work.x + work.width - TRIGGER_SIZE, y: 0 };
    triggerMax = { x: full.x + full.width, y: work.y + TRIGGER_SIZE };
  } else if (corner === 'bottom-left') {
    triggerMin = { x: 0, y: work.y + work.height - TRIGGER_SIZE };
    triggerMax = { x: work.x + TRIGGER_SIZE, y: full.y + full.height };
  } else { // bottom-right
    triggerMin = { x: work.x + work.width - TRIGGER_SIZE, y: work.y + work.height - TRIGGER_SIZE };
    triggerMax = { x: full.x + full.width, y: full.y + full.height };
  }

  return { bounds, triggerMin, triggerMax, side };
}

function getSetting(key, fallback) {
  try {
    return (store.getSettings() || {})[key] ?? fallback;
  } catch (_) {
    return fallback;
  }
}

function createPanelWindow() {
  const corner = getSetting('cornerTrigger', 'top-left');
  const { bounds } = computeLayout(corner);

  panelWindow = new BrowserWindow({
    width: bounds.width,
    height: bounds.height,
    x: bounds.x,
    y: bounds.y,
    frame: false,
    transparent: true,
    backgroundColor: '#00000000',
    alwaysOnTop: true,
    skipTaskbar: true,
    resizable: false,
    movable: false,
    hasShadow: false,
    show: false,
    webPreferences: {
      preload: path.join(__dirname, '..', 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
    },
  });

  panelWindow.loadFile(path.join(__dirname, '..', 'renderer', 'index.html'));
  panelWindow.setVisibleOnAllWorkspaces(true, { visibleOnFullScreen: true });

  panelWindow.on('blur', () => {
    hidePanel();
  });

  // Re-layout when Dock / display metrics change.
  screen.on('display-metrics-changed', () => repositionPanel());
}

function repositionPanel() {
  if (!panelWindow) return;
  const corner = getSetting('cornerTrigger', 'top-left');
  const { bounds, side } = computeLayout(corner);
  panelWindow.setBounds(bounds);
  panelWindow.webContents.send('panel:side', side);
}

function showPanel() {
  if (isPanelVisible || !panelWindow) return;
  isPanelVisible = true;
  panelWindow.setIgnoreMouseEvents(false);
  panelWindow.focus();
  panelWindow.webContents.send('panel:show');
}

function hidePanel() {
  if (!isPanelVisible || !panelWindow) return;
  isPanelVisible = false;
  panelWindow.webContents.send('panel:hide');
  setTimeout(() => {
    if (!isPanelVisible && panelWindow) {
      panelWindow.setIgnoreMouseEvents(true, { forward: true });
    }
  }, 320);
}

function startMousePolling() {
  mousePoller = setInterval(() => {
    const point = screen.getCursorScreenPoint();
    const corner = getSetting('cornerTrigger', 'top-left');
    const { bounds, triggerMin, triggerMax } = computeLayout(corner);

    if (!isPanelVisible) {
      if (
        point.x >= triggerMin.x && point.x <= triggerMax.x &&
        point.y >= triggerMin.y && point.y <= triggerMax.y
      ) {
        showPanel();
      }
    } else {
      // Hide when mouse leaves the panel's column.
      const panelLeft = bounds.x;
      const panelRight = bounds.x + bounds.width;
      if (point.x < panelLeft - 20 || point.x > panelRight + 20) {
        hidePanel();
      }
    }
  }, POLL_INTERVAL);
}

function setupIPC() {
  // Tasks
  ipcMain.handle('tasks:list', () => store.getTasks());
  ipcMain.handle('tasks:get', (_, id) => store.getTask(id));
  ipcMain.handle('tasks:add', (_, title, priority, tags, dueDate) => store.addTask(title, priority, tags, dueDate));
  ipcMain.handle('tasks:toggle', (_, id) => store.toggleTask(id));
  ipcMain.handle('tasks:delete', (_, id) => store.deleteTask(id));
  ipcMain.handle('tasks:update', (_, id, updates) => store.updateTask(id, updates));
  ipcMain.handle('tasks:clearCompleted', () => store.clearCompleted());

  // Subtasks
  ipcMain.handle('subtasks:add', (_, taskId, title) => store.addSubtask(taskId, title));
  ipcMain.handle('subtasks:toggle', (_, taskId, subId) => store.toggleSubtask(taskId, subId));
  ipcMain.handle('subtasks:delete', (_, taskId, subId) => store.deleteSubtask(taskId, subId));
  ipcMain.handle('subtasks:update', (_, taskId, subId, title) => store.updateSubtask(taskId, subId, title));

  // Tags
  ipcMain.handle('tags:list', () => store.getAllTags());
  ipcMain.handle('tags:delete', (_, name) => store.deleteTag(name));
  ipcMain.handle('tags:setColor', (_, name, color) => store.setTagColor(name, color));

  // Snippets (快捷粘贴)
  ipcMain.handle('snippets:list', () => store.getSnippets());
  ipcMain.handle('snippets:add', (_, label, value, type) => store.addSnippet(label, value, type));
  ipcMain.handle('snippets:update', (_, id, updates) => store.updateSnippet(id, updates));
  ipcMain.handle('snippets:delete', (_, id) => store.deleteSnippet(id));
  ipcMain.handle('snippets:reorder', (_, id, targetIndex) => store.reorderSnippet(id, targetIndex));

  // Settings
  ipcMain.handle('settings:get', () => store.getSettings());
  ipcMain.handle('settings:update', (_, updates) => {
    const next = store.updateSettings(updates);
    if (updates.cornerTrigger) repositionPanel();
    return next;
  });

  // Meta
  ipcMain.handle('store:getPath', () => store.getDataPath());

  // Panel
  ipcMain.on('panel:requestHide', () => hidePanel());
}

app.whenReady().then(() => {
  const userDataPath = path.join(app.getPath('userData'), 'data');
  const legacyCandidates = [
    path.join(__dirname, '..', '..', 'data'),
    path.join(app.getPath('appData'), 'corner-todo', 'data'),
    path.join(app.getPath('appData'), 'CornerTodo', 'data'),
  ];
  Store.migrateFromLegacy(legacyCandidates, userDataPath);

  store = new Store(userDataPath);
  console.log('[Main] Data stored at:', store.getDataPath());

  setupIPC();
  createPanelWindow();

  panelWindow.once('ready-to-show', () => {
    panelWindow.showInactive();
    panelWindow.setIgnoreMouseEvents(true, { forward: true });
    // Tell renderer which side to slide from.
    const { side } = computeLayout(getSetting('cornerTrigger', 'top-left'));
    panelWindow.webContents.send('panel:side', side);
    startMousePolling();
  });

  globalShortcut.register('CommandOrControl+Shift+T', () => {
    if (isPanelVisible) hidePanel(); else showPanel();
  });

  app.dock?.hide();
});

app.on('will-quit', () => {
  if (mousePoller) clearInterval(mousePoller);
  globalShortcut.unregisterAll();
});

app.on('window-all-closed', (e) => {
  e.preventDefault();
});
