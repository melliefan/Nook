const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('api', {
  // Tasks
  getTasks: () => ipcRenderer.invoke('tasks:list'),
  getTask: (id) => ipcRenderer.invoke('tasks:get', id),
  addTask: (title, priority, tags, dueDate) => ipcRenderer.invoke('tasks:add', title, priority, tags, dueDate),
  toggleTask: (id) => ipcRenderer.invoke('tasks:toggle', id),
  deleteTask: (id) => ipcRenderer.invoke('tasks:delete', id),
  updateTask: (id, updates) => ipcRenderer.invoke('tasks:update', id, updates),
  clearCompleted: () => ipcRenderer.invoke('tasks:clearCompleted'),
  reorderTask: (id, targetIndex) => ipcRenderer.invoke('tasks:reorder', id, targetIndex),

  // Subtasks
  addSubtask: (taskId, title) => ipcRenderer.invoke('subtasks:add', taskId, title),
  toggleSubtask: (taskId, subId) => ipcRenderer.invoke('subtasks:toggle', taskId, subId),
  deleteSubtask: (taskId, subId) => ipcRenderer.invoke('subtasks:delete', taskId, subId),
  updateSubtask: (taskId, subId, title) => ipcRenderer.invoke('subtasks:update', taskId, subId, title),

  // Tags
  getAllTags: () => ipcRenderer.invoke('tags:list'),
  deleteTag: (name) => ipcRenderer.invoke('tags:delete', name),
  setTagColor: (name, color) => ipcRenderer.invoke('tags:setColor', name, color),

  // Snippets (快捷粘贴)
  getSnippets: () => ipcRenderer.invoke('snippets:list'),
  addSnippet: (label, value, type) => ipcRenderer.invoke('snippets:add', label, value, type),
  updateSnippet: (id, updates) => ipcRenderer.invoke('snippets:update', id, updates),
  deleteSnippet: (id) => ipcRenderer.invoke('snippets:delete', id),
  reorderSnippet: (id, targetIndex) => ipcRenderer.invoke('snippets:reorder', id, targetIndex),

  // Settings
  getSettings: () => ipcRenderer.invoke('settings:get'),
  updateSettings: (updates) => ipcRenderer.invoke('settings:update', updates),

  // Meta
  getStorePath: () => ipcRenderer.invoke('store:getPath'),
  getAppVersion: () => ipcRenderer.invoke('app:getVersion'),
  openExternal: (url) => ipcRenderer.send('shell:openExternal', url),

  // Panel
  requestHide: () => ipcRenderer.send('panel:requestHide'),
  panelResize: (edge, deltaY) => ipcRenderer.send('panel:resize', edge, deltaY),
  panelResizeEnd: () => ipcRenderer.send('panel:resizeEnd'),
  panelWidthResize: (side, deltaX) => ipcRenderer.send('panel:widthResize', side, deltaX),
  panelWidthResizeStart: (side) => ipcRenderer.send('panel:widthResizeStart', side),
  panelWidthResizeEnd: () => ipcRenderer.send('panel:widthResizeEnd'),
  panelPin: (pinned) => ipcRenderer.send('panel:pin', pinned),
  onPanelShow: (cb) => ipcRenderer.on('panel:show', cb),
  onPanelHide: (cb) => ipcRenderer.on('panel:hide', cb),
  onPanelSide: (cb) => ipcRenderer.on('panel:side', (_, side) => cb(side)),
});
