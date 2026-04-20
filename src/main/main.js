const { app, BrowserWindow, screen, ipcMain, globalShortcut, shell } = require('electron');
const path = require('path');
const Store = require('./store');
const { computeLayout: computeLayoutPure, shouldHide, inTrigger } = require('./layout');

let panelWindow = null;
let store = null;
let mousePoller = null;
let isPanelVisible = false;
let hideSuppressUntilMs = 0;
let showTimestamp = 0;
let isPinned = false;
let activeDisplayId = null; // which display the panel is currently on
let widthResizePoller = null;
let widthResizeSide = null;
let widthResizeLastX = 0;
const REPOSITION_GRACE_MS = 2500;
const SHOW_GRACE_MS = 500;

const TRIGGER_SIZE = 40;
const PANEL_WIDTH = 380;
const POLL_INTERVAL = 100;

function getSetting(key, fallback) {
  try {
    return (store.getSettings() || {})[key] ?? fallback;
  } catch (_) {
    return fallback;
  }
}

/** Compute layout for a specific display. */
function computeLayoutForDisplay(corner, display) {
  const ratio = getSetting('panelHeightRatio', 0.75);
  const width = getSetting('panelWidth', PANEL_WIDTH);
  return computeLayoutPure(corner, display, width, TRIGGER_SIZE, ratio);
}

/** Compute layout using the active display (or primary as fallback). */
function computeLayout(corner) {
  const display = activeDisplayId
    ? (screen.getAllDisplays().find(d => d.id === activeDisplayId) || screen.getPrimaryDisplay())
    : screen.getPrimaryDisplay();
  return computeLayoutForDisplay(corner, display);
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

  screen.on('display-metrics-changed', () => repositionPanel());
}

function repositionPanel() {
  if (!panelWindow) return;
  const corner = getSetting('cornerTrigger', 'top-left');
  const { bounds, side } = computeLayout(corner);
  panelWindow.setBounds(bounds);
  panelWindow.webContents.send('panel:side', side);
  hideSuppressUntilMs = Date.now() + REPOSITION_GRACE_MS;
}

/** Move panel to a specific display and show it. */
function showPanelOnDisplay(display) {
  if (isPanelVisible || !panelWindow) return;
  const corner = getSetting('cornerTrigger', 'top-left');
  activeDisplayId = display.id;
  const { bounds, side } = computeLayoutForDisplay(corner, display);
  panelWindow.setBounds(bounds);
  panelWindow.webContents.send('panel:side', side);
  isPanelVisible = true;
  showTimestamp = Date.now();
  panelWindow.setIgnoreMouseEvents(false);
  panelWindow.focus();
  panelWindow.webContents.send('panel:show');
}

function hidePanel() {
  if (!isPanelVisible || !panelWindow) return;
  if (isPinned) return;
  if (Date.now() - showTimestamp < SHOW_GRACE_MS) return;
  isPanelVisible = false;
  panelWindow.webContents.send('panel:hide');
  setTimeout(() => {
    if (!isPanelVisible && panelWindow) {
      panelWindow.setIgnoreMouseEvents(true, { forward: true });
    }
  }, 500);
}

function startMousePolling() {
  mousePoller = setInterval(() => {
    const point = screen.getCursorScreenPoint();
    const corner = getSetting('cornerTrigger', 'top-left');

    if (!isPanelVisible) {
      // Check trigger zones on ALL displays
      const displays = screen.getAllDisplays();
      for (const display of displays) {
        const { triggerMin, triggerMax } = computeLayoutForDisplay(corner, display);
        if (inTrigger(point, triggerMin, triggerMax)) {
          showPanelOnDisplay(display);
          return;
        }
      }
    } else {
      const { bounds, side } = computeLayout(corner);
      if (shouldHide(point, bounds, side, Date.now(), hideSuppressUntilMs)) {
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
  ipcMain.handle('tasks:reorder', (_, id, targetIndex) => store.reorderTask(id, targetIndex));

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
  ipcMain.handle('app:getVersion', () => app.getVersion());

  ipcMain.on('shell:openExternal', (_, url) => {
    if (typeof url === 'string' && /^https?:\/\//.test(url)) {
      shell.openExternal(url);
    }
  });

  // Panel resize (height)
  ipcMain.on('panel:resize', (_, edge, deltaY) => {
    if (!panelWindow) return;
    const bounds = panelWindow.getBounds();
    const display = screen.getDisplayNearestPoint({ x: bounds.x, y: bounds.y });
    const work = display.workArea;
    const minH = 280;
    const maxH = work.height;

    let newH, newY;
    if (edge === 'top') {
      newH = Math.max(minH, Math.min(maxH, bounds.height - deltaY));
      newY = bounds.y + (bounds.height - newH);
    } else {
      newH = Math.max(minH, Math.min(maxH, bounds.height + deltaY));
      newY = bounds.y;
    }
    if (newY < work.y) { newY = work.y; newH = bounds.y + bounds.height - work.y; }
    panelWindow.setBounds({ x: bounds.x, y: newY, width: bounds.width, height: newH });
  });

  ipcMain.on('panel:resizeEnd', () => {
    if (!panelWindow) return;
    const bounds = panelWindow.getBounds();
    const display = screen.getDisplayNearestPoint({ x: bounds.x, y: bounds.y });
    const work = display.workArea;
    const ratio = bounds.height / work.height;
    store.updateSettings({ panelHeightRatio: ratio, panelWidth: bounds.width });
  });

  // Panel resize (width) — driven by main-process polling so it works
  // even when the mouse leaves the renderer window during drag.
  ipcMain.on('panel:widthResizeStart', (_, side) => {
    if (widthResizePoller) return;
    widthResizeSide = side;
    widthResizeLastX = screen.getCursorScreenPoint().x;
    widthResizePoller = setInterval(() => {
      if (!panelWindow) return;
      const curX = screen.getCursorScreenPoint().x;
      const deltaX = curX - widthResizeLastX;
      widthResizeLastX = curX;
      if (deltaX === 0) return;
      const bounds = panelWindow.getBounds();
      const display = screen.getDisplayNearestPoint({ x: bounds.x, y: bounds.y });
      const work = display.workArea;
      const minW = 280;
      const maxW = Math.min(work.width, 600);
      let newW, newX;
      if (widthResizeSide === 'left') {
        newW = Math.max(minW, Math.min(maxW, bounds.width + deltaX));
        newX = bounds.x;
      } else {
        newW = Math.max(minW, Math.min(maxW, bounds.width - deltaX));
        newX = bounds.x + (bounds.width - newW);
      }
      panelWindow.setBounds({ x: newX, y: bounds.y, width: newW, height: bounds.height });
    }, 16);
  });

  ipcMain.on('panel:widthResizeEnd', () => {
    if (widthResizePoller) {
      clearInterval(widthResizePoller);
      widthResizePoller = null;
    }
    if (!panelWindow) return;
    const bounds = panelWindow.getBounds();
    const display = screen.getDisplayNearestPoint({ x: bounds.x, y: bounds.y });
    const work = display.workArea;
    const ratio = bounds.height / work.height;
    store.updateSettings({ panelHeightRatio: ratio, panelWidth: bounds.width });
  });

  // Legacy handler kept for compatibility
  ipcMain.on('panel:widthResize', (_, side, deltaX) => {
    if (!panelWindow) return;
    const bounds = panelWindow.getBounds();
    const display = screen.getDisplayNearestPoint({ x: bounds.x, y: bounds.y });
    const work = display.workArea;
    const minW = 280;
    const maxW = Math.min(work.width, 600);
    let newW, newX;
    if (side === 'left') {
      newW = Math.max(minW, Math.min(maxW, bounds.width + deltaX));
      newX = bounds.x;
    } else {
      newW = Math.max(minW, Math.min(maxW, bounds.width - deltaX));
      newX = bounds.x + (bounds.width - newW);
    }
    panelWindow.setBounds({ x: newX, y: bounds.y, width: newW, height: bounds.height });
  });

  // Panel
  ipcMain.on('panel:pin', (_, pinned) => {
    isPinned = pinned;
    if (!pinned && isPanelVisible) {
      hideSuppressUntilMs = Date.now() + REPOSITION_GRACE_MS;
    }
  });

  ipcMain.on('panel:requestHide', () => {
    isPinned = false;
    hidePanel();
  });
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
    const { side } = computeLayout(getSetting('cornerTrigger', 'top-left'));
    panelWindow.webContents.send('panel:side', side);
    startMousePolling();
  });

  globalShortcut.register('CommandOrControl+Shift+T', () => {
    if (isPanelVisible) hidePanel();
    else {
      const point = screen.getCursorScreenPoint();
      const display = screen.getDisplayNearestPoint(point);
      showPanelOnDisplay(display);
    }
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
