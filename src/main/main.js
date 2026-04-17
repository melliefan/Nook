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

function getPanelOrigin() {
  // workArea excludes menu bar and Dock. If Dock is on the left, workArea.x > 0 —
  // we use that as the panel's starting x so the Dock doesn't cover us.
  const d = screen.getPrimaryDisplay();
  return { x: d.workArea.x, y: d.workArea.y, height: d.workArea.height };
}

function createPanelWindow() {
  const origin = getPanelOrigin();

  panelWindow = new BrowserWindow({
    width: PANEL_WIDTH,
    height: origin.height,
    x: origin.x,
    y: origin.y,
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

  // Reposition the window if Dock/resolution changes.
  const reposition = () => {
    const origin = getPanelOrigin();
    panelWindow.setBounds({
      x: origin.x, y: origin.y,
      width: PANEL_WIDTH, height: origin.height,
    });
  };
  screen.on('display-metrics-changed', reposition);
}

function showPanel() {
  if (isPanelVisible || !panelWindow) return;
  isPanelVisible = true;

  // Capture mouse/keyboard for the panel.
  panelWindow.setIgnoreMouseEvents(false);
  panelWindow.focus();
  panelWindow.webContents.send('panel:show');
}

function hidePanel() {
  if (!isPanelVisible || !panelWindow) return;
  isPanelVisible = false;

  panelWindow.webContents.send('panel:hide');

  // Wait for CSS slide-out animation to finish, then let mouse events pass through.
  setTimeout(() => {
    if (!isPanelVisible && panelWindow) {
      panelWindow.setIgnoreMouseEvents(true, { forward: true });
    }
  }, 320);
}

function startMousePolling() {
  mousePoller = setInterval(() => {
    const point = screen.getCursorScreenPoint();
    const origin = getPanelOrigin();

    if (!isPanelVisible) {
      // Hot corner respects the workArea — hot spot sits just after the Dock (if any).
      if (
        point.x >= origin.x && point.x <= origin.x + TRIGGER_SIZE &&
        point.y >= origin.y && point.y <= origin.y + TRIGGER_SIZE
      ) {
        showPanel();
      }
    } else {
      // Hide when mouse leaves the panel column (right edge).
      if (point.x > origin.x + PANEL_WIDTH + 20) {
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

  // Meta
  ipcMain.handle('store:getPath', () => store.getDataPath());

  // Panel
  ipcMain.on('panel:requestHide', () => hidePanel());
}

app.whenReady().then(() => {
  const userDataPath = path.join(app.getPath('userData'), 'data');
  // Legacy candidates (any earlier productName / project folder) — newest wins.
  const legacyCandidates = [
    path.join(__dirname, '..', '..', 'data'),                                   // project root
    path.join(app.getPath('appData'), 'corner-todo', 'data'),                    // earlier productName
    path.join(app.getPath('appData'), 'CornerTodo', 'data'),
  ];
  Store.migrateFromLegacy(legacyCandidates, userDataPath);

  store = new Store(userDataPath);
  console.log('[Main] Data stored at:', store.getDataPath());

  setupIPC();
  createPanelWindow();

  // Show the (transparent) window once and keep it permanently on screen.
  // Mouse events pass through until the panel slides in.
  panelWindow.once('ready-to-show', () => {
    panelWindow.showInactive();
    panelWindow.setIgnoreMouseEvents(true, { forward: true });
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
