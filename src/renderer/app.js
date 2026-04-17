/* =============================================
   Corner Todo - 完整交互逻辑
   标签多颜色 + 加粗图标 + userData 持久化
   ============================================= */

// ======= DOM =======
const panel = document.getElementById('panel');
const listView = document.getElementById('listView');
const headerCount = document.getElementById('headerCount');
const btnSearch = document.getElementById('btnSearch');
const btnSort = document.getElementById('btnSort');
const btnClose = document.getElementById('btnClose');
const searchBar = document.getElementById('searchBar');
const searchInput = document.getElementById('searchInput');
const searchClear = document.getElementById('searchClear');
const tagFilterBar = document.getElementById('tagFilterBar');
const tagFilterScroll = document.getElementById('tagFilterScroll');
const sortMenu = document.getElementById('sortMenu');
const addTaskBtn = document.getElementById('addTaskBtn');
const addTaskRow = document.getElementById('addTaskRow');
const addTaskInputArea = document.getElementById('addTaskInputArea');
const taskInput = document.getElementById('taskInput');
const addTaskTags = document.getElementById('addTaskTags');
const btnAddDate = document.getElementById('btnAddDate');
const btnAddPriority = document.getElementById('btnAddPriority');
const btnAddTag = document.getElementById('btnAddTag');
const btnConfirmAdd = document.getElementById('btnConfirmAdd');
const btnCancelAdd = document.getElementById('btnCancelAdd');
const addDatePicker = document.getElementById('addDatePicker');
const customDateInput = document.getElementById('customDateInput');
const addPriorityPicker = document.getElementById('addPriorityPicker');
const addTagPicker = document.getElementById('addTagPicker');
const tagPickerInput = document.getElementById('tagPickerInput');
const tagPickerList = document.getElementById('tagPickerList');
const activeList = document.getElementById('activeList');
const completedSection = document.getElementById('completedSection');
const completedHeader = document.getElementById('completedHeader');
const completedList = document.getElementById('completedList');
const completedCount = document.getElementById('completedCount');
const emptyState = document.getElementById('emptyState');
const btnClearCompleted = document.getElementById('btnClearCompleted');
const contextMenu = document.getElementById('contextMenu');
const prioritySubmenu = document.getElementById('prioritySubmenu');
const detailView = document.getElementById('detailView');
const btnBack = document.getElementById('btnBack');
const detailCheckbox = document.getElementById('detailCheckbox');
const detailTitle = document.getElementById('detailTitle');
const detailDesc = document.getElementById('detailDesc');
const subtaskList = document.getElementById('subtaskList');
const subtaskInput = document.getElementById('subtaskInput');
const subtaskProgress = document.getElementById('subtaskProgress');
const detailDateRow = document.getElementById('detailDateRow');
const detailDateLabel = document.getElementById('detailDateLabel');
const detailDateClear = document.getElementById('detailDateClear');
const detailDatePicker = document.getElementById('detailDatePicker');
const detailCustomDate = document.getElementById('detailCustomDate');
const detailPriorityRow = document.getElementById('detailPriorityRow');
const detailPriorityLabel = document.getElementById('detailPriorityLabel');
const detailPriorityIcon = document.getElementById('detailPriorityIcon');
const detailPriorityPicker = document.getElementById('detailPriorityPicker');
const detailTagsList = document.getElementById('detailTagsList');
const detailTagInput = document.getElementById('detailTagInput');
const detailCreatedAt = document.getElementById('detailCreatedAt');
const detailDataPath = document.getElementById('detailDataPath');
const btnDetailDelete = document.getElementById('btnDetailDelete');
const colorPickerPopover = document.getElementById('colorPickerPopover');
const colorPickerGrid = document.getElementById('colorPickerGrid');

// ======= State =======
let tasks = [];
let allTags = {}; // { tagName: { color: '#xxx' | null } }
let currentSort = 'custom';
let searchQuery = '';
let filterTag = null;
let completedCollapsed = false;
let contextTaskId = null;
let currentDetailTaskId = null;
let addPriority = 'none';
let addDueDate = null;
let addTags = [];
let colorPickerTarget = null; // { tagName, origin: 'detail' | 'filter' }

// ======= Tag Color Palette (参考滴答清单) =======
const TAG_COLORS = [
  '#4772FA', // 蓝 (brand)
  '#14AAF5', // 天蓝
  '#158FAD', // 青
  '#6ACCBC', // 薄荷
  '#299438', // 绿
  '#7ECC49', // 草绿
  '#AFBF2E', // 橄榄
  '#FAD000', // 黄
  '#FF9933', // 橙
  '#EB4D3D', // 红
  '#DB4035', // 深红
  '#B8255F', // 莓红
  '#E05194', // 粉
  '#AF38EB', // 紫
  '#884DFF', // 葡萄
  '#96C3EB', // 浅蓝
  '#EB96EB', // 淡紫
  '#FF8D85', // 鲑鱼
  '#CCAC93', // 灰棕
  '#808080', // 灰
];

const PRIORITY_CONFIG = {
  high:   { label: '高优先级', color: '#EB4D3D', order: 0 },
  medium: { label: '中优先级', color: '#FF9A14', order: 1 },
  low:    { label: '低优先级', color: '#4B7BEC', order: 2 },
  none:   { label: '无优先级', color: '#B8B8B8', order: 3 },
};

// ======= Helpers =======
function escapeHtml(t) { const d = document.createElement('div'); d.textContent = t; return d.innerHTML; }

function formatDate(ds) {
  if (!ds) return '';
  const d = new Date(ds + 'T00:00:00');
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const target = new Date(d.getFullYear(), d.getMonth(), d.getDate());
  const diff = Math.round((target - today) / 86400000);
  if (diff === 0) return '今天';
  if (diff === 1) return '明天';
  if (diff === -1) return '昨天';
  if (diff < -1) return `${Math.abs(diff)}天前`;
  if (diff <= 7) return `${diff}天后`;
  return d.toLocaleDateString('zh-CN', { month: 'numeric', day: 'numeric' });
}

function isOverdue(ds) {
  if (!ds) return false;
  return new Date(ds + 'T23:59:59') < new Date();
}

function formatFullTime(iso) {
  return new Date(iso).toLocaleString('zh-CN', { year: 'numeric', month: 'numeric', day: 'numeric', hour: '2-digit', minute: '2-digit' });
}

function getDateValue(type) {
  const d = new Date();
  if (type === 'today') return d.toISOString().split('T')[0];
  if (type === 'tomorrow') { d.setDate(d.getDate() + 1); return d.toISOString().split('T')[0]; }
  if (type === 'nextWeek') { d.setDate(d.getDate() + (8 - d.getDay()) % 7 || 7); return d.toISOString().split('T')[0]; }
  return null;
}

function autoResize(el) { el.style.height = 'auto'; el.style.height = el.scrollHeight + 'px'; }

function closeAllPickers() {
  addDatePicker.classList.add('hidden');
  addPriorityPicker.classList.add('hidden');
  addTagPicker.classList.add('hidden');
  btnAddDate.classList.remove('active');
  btnAddPriority.classList.remove('active');
  btnAddTag.classList.remove('active');
}

function closeDetailPickers() {
  detailDatePicker.classList.add('hidden');
  detailPriorityPicker.classList.add('hidden');
}

function hideColorPicker() {
  colorPickerPopover.classList.add('hidden');
  colorPickerTarget = null;
}

// ======= Tag Color Helpers =======
function getTagColor(tagName) {
  const info = allTags[tagName];
  return (info && info.color) || null;
}

function tagColorStyle(tagName) {
  const c = getTagColor(tagName);
  if (!c) return '';
  return `style="--tag-color: ${c}; --tag-bg: ${c}18"`;
}

function tagChipHtml(tagName, removeAttr) {
  const c = getTagColor(tagName);
  const colorStyle = c ? `style="--tag-color:${c};--tag-bg:${c}18"` : '';
  const removeBtn = removeAttr
    ? `<button class="tag-remove" ${removeAttr}="${escapeHtml(tagName)}">&times;</button>`
    : '';
  return `<span class="tag-chip" ${colorStyle} data-tag-chip="${escapeHtml(tagName)}">#${escapeHtml(tagName)}${removeBtn}</span>`;
}

// ======= Sort =======
function sortTasks(list) {
  if (currentSort === 'custom') return list;
  const s = [...list];
  switch (currentSort) {
    case 'priority': s.sort((a, b) => PRIORITY_CONFIG[a.priority||'none'].order - PRIORITY_CONFIG[b.priority||'none'].order); break;
    case 'dueDate': s.sort((a, b) => { if (!a.dueDate && !b.dueDate) return 0; if (!a.dueDate) return 1; if (!b.dueDate) return -1; return a.dueDate.localeCompare(b.dueDate); }); break;
    case 'title': s.sort((a, b) => a.title.localeCompare(b.title, 'zh-CN')); break;
    case 'created': s.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt)); break;
  }
  return s;
}

function filterTasks(list) {
  let r = list;
  if (searchQuery) {
    const q = searchQuery.toLowerCase();
    r = r.filter(t => t.title.toLowerCase().includes(q) || (t.description && t.description.toLowerCase().includes(q)) || t.tags.some(tg => tg.toLowerCase().includes(q)));
  }
  if (filterTag) r = r.filter(t => t.tags.includes(filterTag));
  return r;
}

// ======= Render List =======
function renderTaskItem(task) {
  const pClass = `priority-${task.priority || 'none'}`;
  const cClass = task.completed ? 'completed' : '';
  const overdue = !task.completed && isOverdue(task.dueDate);

  let metaHtml = '';
  if (task.dueDate) {
    metaHtml += `<span class="task-date ${overdue ? 'overdue' : ''}">${Icons.icon('calendar', 11)}${formatDate(task.dueDate)}</span>`;
  }
  metaHtml += `<span class="task-priority-dot ${pClass}"></span>`;
  const visibleTags = (task.tags || []).slice(0, 2);
  const extraTagCount = (task.tags || []).length - visibleTags.length;
  for (const tag of visibleTags) {
    const c = getTagColor(tag);
    const cs = c ? `style="--tag-color:${c};--tag-bg:${c}18"` : '';
    metaHtml += `<span class="task-tag" ${cs}>#${escapeHtml(tag)}</span>`;
  }
  if (extraTagCount > 0) {
    metaHtml += `<span class="task-tag task-tag-more">+${extraTagCount}</span>`;
  }
  if (task.subtasks && task.subtasks.length > 0) {
    const done = task.subtasks.filter(s => s.completed).length;
    metaHtml += `<span class="task-subtask-count">${Icons.icon('checklist', 11)}${done}/${task.subtasks.length}</span>`;
  }

  let descPreview = '';
  if (task.description && !task.completed) {
    descPreview = `<div class="task-desc-preview">${escapeHtml(task.description.split('\n')[0])}</div>`;
  }

  return `
    <div class="task-item ${cClass}" data-id="${task.id}" draggable="${!task.completed}">
      <div class="task-checkbox ${pClass}" data-action="toggle" data-id="${task.id}">
        <svg class="check-icon" width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="#FFF" stroke-width="4" stroke-linecap="round" stroke-linejoin="round">
          <path d="M4 12l5.5 5.5L20 7"/>
        </svg>
      </div>
      <div class="task-content" data-action="detail" data-id="${task.id}">
        <div class="task-title">${escapeHtml(task.title)}</div>
        ${descPreview}
        <div class="task-meta">${metaHtml}</div>
      </div>
      <div class="task-actions">
        <button class="task-action-btn delete-btn" data-action="delete" data-id="${task.id}" title="删除">
          ${Icons.icon('trash', 14)}
        </button>
      </div>
    </div>`;
}

function renderTagFilterBar() {
  const used = [...new Set(tasks.flatMap(t => t.tags || []))];
  if (used.length === 0) { tagFilterBar.classList.add('hidden'); return; }
  tagFilterBar.classList.remove('hidden');
  let html = `<div class="tag-filter-item tag-filter-all ${!filterTag ? 'active' : ''}" data-tag="">全部</div>`;
  for (const tag of used) {
    const c = getTagColor(tag);
    const isActive = filterTag === tag;
    // Active = full color bg + white text. Inactive = light bg (18% alpha) + colored text.
    const style = c
      ? `style="--tag-active-bg:${c};background:${isActive ? c : c + '18'};color:${isActive ? '#FFF' : c}"`
      : '';
    html += `<div class="tag-filter-item ${isActive ? 'active' : ''}" data-tag="${escapeHtml(tag)}" ${style}>#${escapeHtml(tag)}</div>`;
  }
  tagFilterScroll.innerHTML = html;
}

function render() {
  const active = filterTasks(sortTasks(tasks.filter(t => !t.completed)));
  const completed = filterTasks(tasks.filter(t => t.completed));
  activeList.innerHTML = active.map(renderTaskItem).join('');
  if (completed.length > 0) {
    completedSection.classList.remove('hidden');
    completedCount.textContent = completed.length;
    if (!completedCollapsed) { completedList.innerHTML = completed.map(renderTaskItem).join(''); completedSection.classList.remove('collapsed'); }
    else { completedSection.classList.add('collapsed'); }
  } else { completedSection.classList.add('hidden'); }
  headerCount.textContent = tasks.filter(t => !t.completed).length;
  emptyState.classList.toggle('visible', active.length === 0 && completed.length === 0);
  renderTagFilterBar();
}

// ======= Data =======
async function loadTasks() {
  tasks = await window.api.getTasks();
  allTags = await window.api.getAllTags();
  render();
}

async function addTask() {
  const raw = taskInput.value.trim();
  if (!raw) return;
  const inlineTags = [];
  const title = raw.replace(/#([\w\u4e00-\u9fff]+)/g, (_, tag) => { inlineTags.push(tag); return ''; }).trim();
  if (!title) return;
  const finalTags = [...new Set([...addTags, ...inlineTags])];
  const task = await window.api.addTask(title, addPriority, finalTags, addDueDate);
  tasks.unshift(task);
  allTags = await window.api.getAllTags();
  taskInput.value = ''; addPriority = 'none'; addDueDate = null; addTags = [];
  updateAddFormUI(); closeAddTaskInput(); render();
}

async function toggleTask(id) {
  const u = await window.api.toggleTask(id);
  const i = tasks.findIndex(t => t.id === id);
  if (i !== -1 && u) tasks[i] = u;
  render();
  if (currentDetailTaskId === id) renderDetail(id);
}

async function deleteTask(id) {
  await window.api.deleteTask(id);
  tasks = tasks.filter(t => t.id !== id);
  render();
  if (currentDetailTaskId === id) navigateToList();
}

async function updateTaskField(id, updates) {
  const u = await window.api.updateTask(id, updates);
  const i = tasks.findIndex(t => t.id === id);
  if (i !== -1 && u) tasks[i] = u;
  if (updates.tags) allTags = await window.api.getAllTags();
  render();
  return u;
}

// ======= Add Task UI =======
function openAddTaskInput() { addTaskRow.classList.add('hidden'); addTaskInputArea.classList.remove('hidden'); taskInput.focus(); }
function closeAddTaskInput() { addTaskInputArea.classList.add('hidden'); addTaskRow.classList.remove('hidden'); taskInput.value = ''; addPriority = 'none'; addDueDate = null; addTags = []; updateAddFormUI(); closeAllPickers(); }

function updateAddFormUI() {
  if (addPriority !== 'none') { btnAddPriority.style.color = PRIORITY_CONFIG[addPriority].color; btnAddPriority.classList.add('active'); }
  else { btnAddPriority.style.color = ''; btnAddPriority.classList.remove('active'); }
  if (addDueDate) { btnAddDate.classList.add('active'); btnAddDate.style.color = isOverdue(addDueDate) ? '#EB4D3D' : '#4772FA'; }
  else { btnAddDate.classList.remove('active'); btnAddDate.style.color = ''; }
  if (addTags.length > 0) {
    addTaskTags.classList.remove('hidden');
    addTaskTags.innerHTML = addTags.map(t => tagChipHtml(t, 'data-tag')).join('');
    btnAddTag.classList.add('active');
  } else { addTaskTags.classList.add('hidden'); addTaskTags.innerHTML = ''; btnAddTag.classList.remove('active'); }
  addPriorityPicker.querySelectorAll('.priority-option').forEach(el => el.classList.toggle('selected', el.dataset.priority === addPriority));
}

function renderTagPickerList(input) {
  const q = (input || '').toLowerCase();
  const allNames = Object.keys(allTags);
  const used = [...new Set([...allNames, ...addTags])];
  const filtered = q ? used.filter(t => t.toLowerCase().includes(q)) : used;
  let html = '';
  if (q && !used.includes(q) && !addTags.includes(q)) {
    html += `<div class="tag-picker-item" data-tag="${escapeHtml(q)}"><span class="tag-color-dot" style="background:#4772FA"></span><span>创建 "${escapeHtml(q)}"</span></div>`;
  }
  for (const tag of filtered) {
    const c = getTagColor(tag) || '#4772FA';
    const sel = addTags.includes(tag);
    html += `<div class="tag-picker-item ${sel ? 'selected' : ''}" data-tag="${escapeHtml(tag)}"><span class="tag-color-dot" style="background:${c}"></span><span>#${escapeHtml(tag)}</span></div>`;
  }
  tagPickerList.innerHTML = html || '<div style="padding:8px 12px;font-size:12px;color:rgba(25,25,25,0.4)">输入标签名后回车创建</div>';
}

taskInput.addEventListener('input', () => {
  const val = taskInput.value;
  const match = val.match(/#([\w\u4e00-\u9fff]+)\s$/);
  if (match) {
    if (!addTags.includes(match[1])) addTags.push(match[1]);
    taskInput.value = val.replace(/#[\w\u4e00-\u9fff]+\s$/, '');
    updateAddFormUI();
  }
});

// ======= Navigation =======
function navigateToDetail(taskId) {
  currentDetailTaskId = taskId;
  detailView.classList.remove('hidden');
  listView.classList.add('slide-left');
  detailView.classList.add('slide-in');
  renderDetail(taskId);
}

function navigateToList() {
  if (currentDetailTaskId) saveDetailChanges();
  currentDetailTaskId = null;
  listView.classList.remove('slide-left');
  detailView.classList.remove('slide-in');
  setTimeout(() => detailView.classList.add('hidden'), 300);
  closeDetailPickers(); hideColorPicker();
}

// ======= Detail =======
function renderDetail(taskId) {
  const task = tasks.find(t => t.id === taskId);
  if (!task) return;

  const pClass = `priority-${task.priority || 'none'}`;
  detailCheckbox.className = `task-checkbox detail-checkbox ${pClass}`;
  if (task.completed) {
    detailCheckbox.style.background = PRIORITY_CONFIG[task.priority||'none'].color;
    detailCheckbox.style.borderColor = PRIORITY_CONFIG[task.priority||'none'].color;
    detailCheckbox.querySelector('.check-icon').style.display = 'block';
  } else {
    detailCheckbox.style.background = ''; detailCheckbox.style.borderColor = '';
    detailCheckbox.querySelector('.check-icon').style.display = 'none';
  }

  detailTitle.value = task.title;
  detailTitle.classList.toggle('completed-title', task.completed);
  autoResize(detailTitle);

  detailDesc.value = task.description || '';
  autoResize(detailDesc);

  renderSubtasks(task);

  if (task.dueDate) {
    detailDateLabel.textContent = formatDate(task.dueDate) + ' (' + task.dueDate + ')';
    detailDateLabel.classList.add('has-value');
    detailDateLabel.classList.toggle('overdue', isOverdue(task.dueDate) && !task.completed);
    detailDateClear.classList.remove('hidden');
  } else {
    detailDateLabel.textContent = '截止日期';
    detailDateLabel.classList.remove('has-value', 'overdue');
    detailDateClear.classList.add('hidden');
  }

  const pc = PRIORITY_CONFIG[task.priority || 'none'];
  detailPriorityLabel.textContent = pc.label;
  if (task.priority !== 'none') {
    detailPriorityLabel.classList.add('has-value');
    detailPriorityIcon.style.color = pc.color;
  } else {
    detailPriorityLabel.classList.remove('has-value');
    detailPriorityIcon.style.color = '';
  }

  renderDetailTags(task);
  detailCreatedAt.textContent = '创建于 ' + formatFullTime(task.createdAt);
}

function renderSubtasks(task) {
  const subs = task.subtasks || [];
  const done = subs.filter(s => s.completed).length;
  subtaskProgress.textContent = subs.length > 0 ? `${done}/${subs.length}` : '';
  subtaskList.innerHTML = subs.map(sub => `
    <div class="subtask-item ${sub.completed ? 'completed' : ''}" data-sub-id="${sub.id}">
      <div class="subtask-checkbox" data-sub-action="toggle" data-sub-id="${sub.id}">
        <svg class="sub-check-icon" width="9" height="9" viewBox="0 0 24 24" fill="none">
          <path d="M4 12L9.5 17.5L20 6.5" stroke="#FFF" stroke-width="4.5" stroke-linecap="round" stroke-linejoin="round"/>
        </svg>
      </div>
      <input class="subtask-title" value="${escapeHtml(sub.title)}" data-sub-action="edit" data-sub-id="${sub.id}" ${sub.completed ? 'readonly' : ''}>
      <button class="subtask-delete" data-sub-action="delete" data-sub-id="${sub.id}">
        ${Icons.icon('close', 12)}
      </button>
    </div>`).join('');
}

function renderDetailTags(task) {
  detailTagsList.innerHTML = (task.tags || []).map(tag =>
    tagChipHtml(tag, 'data-detail-tag-remove')
  ).join('');
}

async function saveDetailChanges() {
  if (!currentDetailTaskId) return;
  const task = tasks.find(t => t.id === currentDetailTaskId);
  if (!task) return;
  const nt = detailTitle.value.trim();
  const nd = detailDesc.value;
  if (nt !== task.title || nd !== task.description) {
    await updateTaskField(currentDetailTaskId, { title: nt || task.title, description: nd });
  }
}

// ======= Color Picker =======
function showColorPicker(tagName, anchorEl, origin) {
  colorPickerTarget = { tagName, origin };
  const rect = anchorEl.getBoundingClientRect();
  const popoverW = 204;
  const popoverH = 160;
  const panelW = 380;
  // horizontally: try to align with chip, but clamp within panel
  let left = rect.left;
  if (left + popoverW > panelW - 8) left = panelW - popoverW - 8;
  if (left < 8) left = 8;
  // vertically: prefer below, fallback above
  let top = rect.bottom + 6;
  if (top + popoverH > window.innerHeight - 8) top = rect.top - popoverH - 6;
  colorPickerPopover.style.left = left + 'px';
  colorPickerPopover.style.top = top + 'px';
  const currentColor = getTagColor(tagName);
  colorPickerGrid.innerHTML = TAG_COLORS.map(c => {
    const isActive = c === currentColor;
    return `<div class="color-swatch ${isActive ? 'active' : ''}" data-color="${c}" style="background:${c};color:#FFF">
      <span class="swatch-check">${Icons.icon('check-circle', 14)}</span>
    </div>`;
  }).join('');
  colorPickerPopover.classList.remove('hidden');
}

colorPickerGrid.addEventListener('click', async (e) => {
  const swatch = e.target.closest('.color-swatch');
  if (!swatch || !colorPickerTarget) return;
  const color = swatch.dataset.color;
  await window.api.setTagColor(colorPickerTarget.tagName, color);
  allTags = await window.api.getAllTags();
  render();
  if (currentDetailTaskId) renderDetail(currentDetailTaskId);
  hideColorPicker();
});

// ======= Event Listeners =======
addTaskBtn.addEventListener('click', openAddTaskInput);
btnConfirmAdd.addEventListener('click', addTask);
btnCancelAdd.addEventListener('click', closeAddTaskInput);
taskInput.addEventListener('keydown', (e) => { if (e.key === 'Enter') addTask(); if (e.key === 'Escape') closeAddTaskInput(); });

addTaskTags.addEventListener('click', (e) => {
  const btn = e.target.closest('.tag-remove');
  if (!btn) return;
  addTags = addTags.filter(t => t !== btn.dataset.tag);
  updateAddFormUI();
});

btnAddDate.addEventListener('click', (e) => { e.stopPropagation(); const h = addDatePicker.classList.contains('hidden'); closeAllPickers(); if (h) { addDatePicker.classList.remove('hidden'); btnAddDate.classList.add('active'); } });
addDatePicker.addEventListener('click', (e) => { const o = e.target.closest('.date-option'); if (!o) return; const t = o.dataset.date; if (t === 'clear') addDueDate = null; else if (t === 'custom') return; else addDueDate = getDateValue(t); updateAddFormUI(); closeAllPickers(); });
customDateInput.addEventListener('change', (e) => { addDueDate = e.target.value || null; updateAddFormUI(); closeAllPickers(); });

btnAddPriority.addEventListener('click', (e) => { e.stopPropagation(); const h = addPriorityPicker.classList.contains('hidden'); closeAllPickers(); if (h) { addPriorityPicker.classList.remove('hidden'); btnAddPriority.classList.add('active'); } });
addPriorityPicker.addEventListener('click', (e) => { const o = e.target.closest('.priority-option'); if (!o) return; addPriority = o.dataset.priority; updateAddFormUI(); closeAllPickers(); });

btnAddTag.addEventListener('click', (e) => { e.stopPropagation(); const h = addTagPicker.classList.contains('hidden'); closeAllPickers(); if (h) { addTagPicker.classList.remove('hidden'); btnAddTag.classList.add('active'); tagPickerInput.value = ''; renderTagPickerList(''); tagPickerInput.focus(); } });
tagPickerInput.addEventListener('input', () => renderTagPickerList(tagPickerInput.value));
tagPickerInput.addEventListener('keydown', (e) => { if (e.key === 'Enter') { const v = tagPickerInput.value.trim(); if (v && !addTags.includes(v)) { addTags.push(v); updateAddFormUI(); tagPickerInput.value = ''; renderTagPickerList(''); } } if (e.key === 'Escape') closeAllPickers(); });
tagPickerList.addEventListener('click', (e) => { const item = e.target.closest('.tag-picker-item'); if (!item) return; const tag = item.dataset.tag; if (addTags.includes(tag)) addTags = addTags.filter(t => t !== tag); else addTags.push(tag); updateAddFormUI(); renderTagPickerList(tagPickerInput.value); });

btnSearch.addEventListener('click', () => { searchBar.classList.toggle('hidden'); if (!searchBar.classList.contains('hidden')) searchInput.focus(); else { searchInput.value = ''; searchQuery = ''; render(); } });
searchInput.addEventListener('input', () => { searchQuery = searchInput.value; render(); });
searchClear.addEventListener('click', () => {
  if (searchInput.value) {
    // Has text → clear input, keep focus
    searchInput.value = '';
    searchQuery = '';
    render();
    searchInput.focus();
  } else {
    // Already empty → close the search bar
    searchBar.classList.add('hidden');
    searchQuery = '';
    render();
  }
});

btnSort.addEventListener('click', (e) => { e.stopPropagation(); sortMenu.classList.toggle('hidden'); });
sortMenu.addEventListener('click', (e) => { const o = e.target.closest('.sort-option'); if (!o) return; currentSort = o.dataset.sort; sortMenu.querySelectorAll('.sort-option').forEach(el => el.classList.toggle('active', el.dataset.sort === currentSort)); sortMenu.classList.add('hidden'); render(); });

tagFilterScroll.addEventListener('click', (e) => { const item = e.target.closest('.tag-filter-item'); if (!item) return; filterTag = item.dataset.tag || null; render(); });

btnClose.addEventListener('click', () => window.api.requestHide());

function handleTaskListClick(e) { const el = e.target.closest('[data-action]'); if (!el) return; const a = el.dataset.action; const id = parseInt(el.dataset.id); if (a === 'toggle') toggleTask(id); if (a === 'delete') deleteTask(id); if (a === 'detail') navigateToDetail(id); }
activeList.addEventListener('click', handleTaskListClick);
completedList.addEventListener('click', handleTaskListClick);

function handleContextMenu(e) { e.preventDefault(); const item = e.target.closest('.task-item'); if (!item) return; contextTaskId = parseInt(item.dataset.id); contextMenu.style.left = Math.min(e.clientX, 220) + 'px'; contextMenu.style.top = Math.min(e.clientY, window.innerHeight - 140) + 'px'; contextMenu.classList.remove('hidden'); }
activeList.addEventListener('contextmenu', handleContextMenu);
completedList.addEventListener('contextmenu', handleContextMenu);

function hideContextMenu() { contextMenu.classList.add('hidden'); prioritySubmenu.classList.add('hidden'); contextTaskId = null; }

contextMenu.addEventListener('click', (e) => {
  const item = e.target.closest('.context-item');
  const sub = e.target.closest('.context-submenu');
  if (sub && sub.dataset.action === 'priority') { const r = sub.getBoundingClientRect(); prioritySubmenu.style.left = Math.min(r.right + 4, 260) + 'px'; prioritySubmenu.style.top = r.top + 'px'; prioritySubmenu.classList.remove('hidden'); return; }
  if (!item) return;
  if (item.dataset.action === 'edit' && contextTaskId) navigateToDetail(contextTaskId);
  if (item.dataset.action === 'delete' && contextTaskId) deleteTask(contextTaskId);
  hideContextMenu();
});

prioritySubmenu.addEventListener('click', (e) => { const item = e.target.closest('.context-item'); if (!item || !contextTaskId) return; updateTaskField(contextTaskId, { priority: item.dataset.priority }); hideContextMenu(); });

completedHeader.addEventListener('click', () => { completedCollapsed = !completedCollapsed; render(); });
btnClearCompleted.addEventListener('click', async (e) => { e.stopPropagation(); await window.api.clearCompleted(); tasks = tasks.filter(t => !t.completed); render(); });

// Detail
btnBack.addEventListener('click', navigateToList);
detailCheckbox.addEventListener('click', () => { if (currentDetailTaskId) toggleTask(currentDetailTaskId); });
detailTitle.addEventListener('input', () => autoResize(detailTitle));
detailDesc.addEventListener('input', () => autoResize(detailDesc));
detailTitle.addEventListener('blur', saveDetailChanges);
detailDesc.addEventListener('blur', saveDetailChanges);

detailDateRow.addEventListener('click', (e) => { if (e.target.closest('.prop-clear')) return; e.stopPropagation(); const h = detailDatePicker.classList.contains('hidden'); closeDetailPickers(); if (h) detailDatePicker.classList.remove('hidden'); });
detailDateClear.addEventListener('click', async (e) => { e.stopPropagation(); await updateTaskField(currentDetailTaskId, { dueDate: null }); renderDetail(currentDetailTaskId); });
detailDatePicker.addEventListener('click', async (e) => { const o = e.target.closest('.date-option'); if (!o) return; const t = o.dataset.date; let v = null; if (t === 'clear') v = null; else if (t === 'custom') return; else v = getDateValue(t); await updateTaskField(currentDetailTaskId, { dueDate: v }); renderDetail(currentDetailTaskId); closeDetailPickers(); });
detailCustomDate.addEventListener('change', async (e) => { await updateTaskField(currentDetailTaskId, { dueDate: e.target.value || null }); renderDetail(currentDetailTaskId); closeDetailPickers(); });

detailPriorityRow.addEventListener('click', (e) => { e.stopPropagation(); const h = detailPriorityPicker.classList.contains('hidden'); closeDetailPickers(); if (h) detailPriorityPicker.classList.remove('hidden'); });
detailPriorityPicker.addEventListener('click', async (e) => { const o = e.target.closest('.priority-option'); if (!o) return; await updateTaskField(currentDetailTaskId, { priority: o.dataset.priority }); renderDetail(currentDetailTaskId); closeDetailPickers(); });

// Detail tags — click tag chip to pick color, click remove to remove
detailTagInput.addEventListener('keydown', async (e) => {
  if (e.key === 'Enter') {
    const v = detailTagInput.value.trim().replace(/^#/, '');
    if (!v) return;
    const task = tasks.find(t => t.id === currentDetailTaskId);
    if (!task) return;
    const tags = [...new Set([...(task.tags || []), v])];
    await updateTaskField(currentDetailTaskId, { tags });
    renderDetail(currentDetailTaskId);
    detailTagInput.value = '';
  }
  if (e.key === 'Backspace' && !detailTagInput.value) {
    const task = tasks.find(t => t.id === currentDetailTaskId);
    if (task && task.tags.length > 0) {
      await updateTaskField(currentDetailTaskId, { tags: task.tags.slice(0, -1) });
      renderDetail(currentDetailTaskId);
    }
  }
});

detailTagsList.addEventListener('click', async (e) => {
  const rmBtn = e.target.closest('[data-detail-tag-remove]');
  if (rmBtn) {
    const tagToRemove = rmBtn.dataset.detailTagRemove;
    const task = tasks.find(t => t.id === currentDetailTaskId);
    if (!task) return;
    await updateTaskField(currentDetailTaskId, { tags: task.tags.filter(t => t !== tagToRemove) });
    renderDetail(currentDetailTaskId);
    return;
  }
  // Click on chip itself → open color picker
  const chip = e.target.closest('[data-tag-chip]');
  if (chip) {
    showColorPicker(chip.dataset.tagChip, chip, 'detail');
  }
});

// Subtasks
subtaskInput.addEventListener('keydown', async (e) => {
  if (e.key === 'Enter') {
    const title = subtaskInput.value.trim();
    if (!title || !currentDetailTaskId) return;
    await window.api.addSubtask(currentDetailTaskId, title);
    const u = await window.api.getTask(currentDetailTaskId);
    const i = tasks.findIndex(t => t.id === currentDetailTaskId);
    if (i !== -1 && u) tasks[i] = u;
    renderDetail(currentDetailTaskId); render();
    subtaskInput.value = ''; subtaskInput.focus();
  }
});

subtaskList.addEventListener('click', async (e) => {
  const el = e.target.closest('[data-sub-action]');
  if (!el) return;
  const subId = parseInt(el.dataset.subId);
  if (el.dataset.subAction === 'toggle') await window.api.toggleSubtask(currentDetailTaskId, subId);
  if (el.dataset.subAction === 'delete') await window.api.deleteSubtask(currentDetailTaskId, subId);
  const u = await window.api.getTask(currentDetailTaskId);
  const i = tasks.findIndex(t => t.id === currentDetailTaskId);
  if (i !== -1 && u) tasks[i] = u;
  renderDetail(currentDetailTaskId); render();
});

subtaskList.addEventListener('focusout', async (e) => {
  const inp = e.target.closest('[data-sub-action="edit"]');
  if (!inp) return;
  const subId = parseInt(inp.dataset.subId);
  const newT = inp.value.trim();
  if (!newT) return;
  await window.api.updateSubtask(currentDetailTaskId, subId, newT);
  const u = await window.api.getTask(currentDetailTaskId);
  const i = tasks.findIndex(t => t.id === currentDetailTaskId);
  if (i !== -1 && u) tasks[i] = u;
});

btnDetailDelete.addEventListener('click', () => { if (currentDetailTaskId) deleteTask(currentDetailTaskId); });

// Global
document.addEventListener('click', (e) => {
  if (!contextMenu.contains(e.target) && !prioritySubmenu.contains(e.target)) hideContextMenu();
  if (!sortMenu.contains(e.target) && !btnSort.contains(e.target)) sortMenu.classList.add('hidden');
  if (!addTaskInputArea.contains(e.target) && !addTaskBtn.contains(e.target)) closeAllPickers();
  if (!detailDateRow.contains(e.target) && !detailDatePicker.contains(e.target)) detailDatePicker.classList.add('hidden');
  if (!detailPriorityRow.contains(e.target) && !detailPriorityPicker.contains(e.target)) detailPriorityPicker.classList.add('hidden');
  if (!colorPickerPopover.contains(e.target) && !detailTagsList.contains(e.target)) hideColorPicker();
});

document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') { hideContextMenu(); hideColorPicker(); if (detailView.classList.contains('slide-in')) navigateToList(); }
  if ((e.metaKey || e.ctrlKey) && e.key === 'f') { e.preventDefault(); searchBar.classList.remove('hidden'); searchInput.focus(); }
  if ((e.metaKey || e.ctrlKey) && e.key === 'n') { e.preventDefault(); if (detailView.classList.contains('slide-in')) navigateToList(); openAddTaskInput(); }
});

// Drag & Drop
let draggedId = null;
function setupDragDrop(list) {
  list.addEventListener('dragstart', (e) => { const item = e.target.closest('.task-item'); if (!item) return; draggedId = parseInt(item.dataset.id); item.classList.add('dragging'); e.dataTransfer.effectAllowed = 'move'; list.classList.add('drag-over'); });
  list.addEventListener('dragend', (e) => { const item = e.target.closest('.task-item'); if (item) item.classList.remove('dragging'); list.classList.remove('drag-over'); list.querySelectorAll('.drag-target-above,.drag-target-below').forEach(el => el.classList.remove('drag-target-above', 'drag-target-below')); draggedId = null; });
  list.addEventListener('dragover', (e) => { e.preventDefault(); e.dataTransfer.dropEffect = 'move'; const item = e.target.closest('.task-item'); if (!item || parseInt(item.dataset.id) === draggedId) return; list.querySelectorAll('.drag-target-above,.drag-target-below').forEach(el => el.classList.remove('drag-target-above', 'drag-target-below')); const r = item.getBoundingClientRect(); (e.clientY < r.top + r.height / 2) ? item.classList.add('drag-target-above') : item.classList.add('drag-target-below'); });
  list.addEventListener('drop', (e) => { e.preventDefault(); const item = e.target.closest('.task-item'); if (!item || draggedId === null) return; const tid = parseInt(item.dataset.id); if (tid === draggedId) return; const active = tasks.filter(t => !t.completed); const di = active.findIndex(t => t.id === draggedId); const ti = active.findIndex(t => t.id === tid); if (di === -1 || ti === -1) return; const [mv] = active.splice(di, 1); const r = item.getBoundingClientRect(); const ins = e.clientY < r.top + r.height / 2 ? ti : ti + 1; active.splice(ins > di ? ins - 1 : ins, 0, mv); tasks = [...active, ...tasks.filter(t => t.completed)]; render(); });
}
setupDragDrop(activeList);

// Panel
window.api.onPanelShow(() => { panel.classList.add('visible'); loadTasks(); loadSnippets(); });
window.api.onPanelHide(() => { panel.classList.remove('visible'); hideContextMenu(); closeAddTaskInput(); hideColorPicker(); if (detailView.classList.contains('slide-in')) saveDetailChanges(); });

// Show data path on first load
(async () => {
  try {
    const p = await window.api.getStorePath();
    if (detailDataPath) detailDataPath.textContent = `数据: ${p}`;
  } catch (_) {}
})();

// =============================================
// Snippets (快捷粘贴)
// =============================================
const snippetsSection = document.getElementById('snippetsSection');
const snippetsHeader = document.getElementById('snippetsHeader');
const snippetsBody = document.getElementById('snippetsBody');
const snippetsList = document.getElementById('snippetsList');
const snippetsCount = document.getElementById('snippetsCount');
const btnAddSnippet = document.getElementById('btnAddSnippet');
const snippetAddForm = document.getElementById('snippetAddForm');
const snippetLabelInput = document.getElementById('snippetLabelInput');
const snippetValueInput = document.getElementById('snippetValueInput');
const snippetIsPassword = document.getElementById('snippetIsPassword');
const btnCancelSnippet = document.getElementById('btnCancelSnippet');
const btnConfirmSnippet = document.getElementById('btnConfirmSnippet');
const toast = document.getElementById('toast');

let snippets = [];
let editingSnippetId = null;
let revealedSnippetIds = new Set();

function maskValue(v) {
  if (!v) return '';
  if (v.length <= 4) return '•'.repeat(v.length);
  return '•'.repeat(Math.min(v.length, 10));
}

function renderSnippets() {
  snippetsCount.textContent = snippets.length > 0 ? snippets.length : '';
  if (snippets.length === 0) {
    snippetsList.innerHTML = `<div class="snippets-empty">点击 + 添加常用命令或密码</div>`;
    return;
  }
  snippetsList.innerHTML = snippets.map(s => {
    const isRevealed = revealedSnippetIds.has(s.id);
    const isMasked = s.type === 'password' && !isRevealed;
    const displayValue = isMasked ? maskValue(s.value) : s.value;
    const eyeIcon = s.type === 'password' ? `
      <button class="snippet-btn" data-snip-action="reveal" data-id="${s.id}" title="${isRevealed ? '隐藏' : '显示'}">
        ${isRevealed ? Icons.icon('eye-closed', 13) : Icons.icon('eye', 13)}
      </button>` : '';
    return `
      <div class="snippet-item" data-id="${s.id}" data-snip-action="copy">
        <span class="snippet-label">${escapeHtml(s.label || '未命名')}</span>
        <span class="snippet-value ${isMasked ? 'masked' : ''}">${escapeHtml(displayValue)}</span>
        <div class="snippet-actions">
          ${eyeIcon}
          <button class="snippet-btn" data-snip-action="edit" data-id="${s.id}" title="编辑">
            ${Icons.icon('pen', 13)}
          </button>
          <button class="snippet-btn danger" data-snip-action="delete" data-id="${s.id}" title="删除">
            ${Icons.icon('trash', 13)}
          </button>
        </div>
      </div>`;
  }).join('');
}

async function loadSnippets() {
  snippets = await window.api.getSnippets();
  renderSnippets();
}

function openSnippetForm(snippet) {
  editingSnippetId = snippet ? snippet.id : null;
  snippetLabelInput.value = snippet ? snippet.label : '';
  snippetValueInput.value = snippet ? snippet.value : '';
  snippetIsPassword.checked = snippet ? snippet.type === 'password' : false;
  snippetValueInput.type = snippetIsPassword.checked ? 'password' : 'text';
  snippetAddForm.classList.remove('hidden');
  // Ensure panel is expanded
  snippetsSection.classList.remove('collapsed');
  setTimeout(() => snippetLabelInput.focus(), 50);
}

function closeSnippetForm() {
  snippetAddForm.classList.add('hidden');
  snippetLabelInput.value = '';
  snippetValueInput.value = '';
  snippetIsPassword.checked = false;
  editingSnippetId = null;
}

async function saveSnippet() {
  const label = snippetLabelInput.value.trim();
  const value = snippetValueInput.value;
  if (!label || !value) return;
  const type = snippetIsPassword.checked ? 'password' : 'text';
  if (editingSnippetId) {
    await window.api.updateSnippet(editingSnippetId, { label, value, type });
  } else {
    await window.api.addSnippet(label, value, type);
  }
  snippets = await window.api.getSnippets();
  renderSnippets();
  closeSnippetForm();
}

function showToast(msg) {
  toast.textContent = msg;
  toast.classList.remove('hidden');
  clearTimeout(showToast._t);
  showToast._t = setTimeout(() => toast.classList.add('hidden'), 1500);
}

async function copySnippet(id) {
  const s = snippets.find(x => x.id === id);
  if (!s) return;
  try {
    await navigator.clipboard.writeText(s.value);
  } catch (e) {
    // fallback
    const ta = document.createElement('textarea');
    ta.value = s.value;
    document.body.appendChild(ta);
    ta.select();
    document.execCommand('copy');
    document.body.removeChild(ta);
  }
  showToast(`已复制: ${s.label}`);
  // Flash feedback on the row
  const row = snippetsList.querySelector(`[data-id="${id}"]`);
  if (row) {
    row.classList.add('copied');
    setTimeout(() => row.classList.remove('copied'), 800);
  }
}

// Header click → toggle collapsed
snippetsHeader.addEventListener('click', (e) => {
  if (e.target.closest('.snippets-add-btn')) return;
  snippetsSection.classList.toggle('collapsed');
});

// Add button
btnAddSnippet.addEventListener('click', (e) => {
  e.stopPropagation();
  openSnippetForm(null);
});

// Form actions
btnCancelSnippet.addEventListener('click', closeSnippetForm);
btnConfirmSnippet.addEventListener('click', saveSnippet);

snippetIsPassword.addEventListener('change', () => {
  snippetValueInput.type = snippetIsPassword.checked ? 'password' : 'text';
});

function handleSnippetFormKey(e) {
  if (e.key === 'Enter' && (e.metaKey || e.ctrlKey)) saveSnippet();
  if (e.key === 'Escape') closeSnippetForm();
}
snippetLabelInput.addEventListener('keydown', handleSnippetFormKey);
snippetValueInput.addEventListener('keydown', (e) => {
  if (e.key === 'Enter') saveSnippet();
  if (e.key === 'Escape') closeSnippetForm();
});

// List click handling (copy / edit / delete / reveal)
snippetsList.addEventListener('click', async (e) => {
  const actionEl = e.target.closest('[data-snip-action]');
  if (!actionEl) return;
  const action = actionEl.dataset.snipAction;
  const id = parseInt(actionEl.dataset.id);

  // Actions on buttons should not also trigger the row copy
  if (action === 'edit') {
    e.stopPropagation();
    const s = snippets.find(x => x.id === id);
    if (s) openSnippetForm(s);
    return;
  }
  if (action === 'delete') {
    e.stopPropagation();
    await window.api.deleteSnippet(id);
    snippets = await window.api.getSnippets();
    revealedSnippetIds.delete(id);
    renderSnippets();
    return;
  }
  if (action === 'reveal') {
    e.stopPropagation();
    if (revealedSnippetIds.has(id)) revealedSnippetIds.delete(id);
    else revealedSnippetIds.add(id);
    renderSnippets();
    return;
  }
  if (action === 'copy') {
    copySnippet(id);
  }
});

// Initial snippet load (tasks already loaded above)
loadSnippets();

// =============================================
// Settings (热角位置)
// =============================================
const btnSettings = document.getElementById('btnSettings');
const settingsPopover = document.getElementById('settingsPopover');
const footerHint = document.getElementById('footerHint');

const CORNER_LABELS = {
  'top-left': '左上角',
  'top-right': '右上角',
  'bottom-left': '左下角',
  'bottom-right': '右下角',
};

let currentCorner = 'top-left';

function updateCornerUI() {
  // Highlight active button
  document.querySelectorAll('.corner-btn').forEach(b => {
    b.classList.toggle('active', b.dataset.corner === currentCorner);
  });
  // Update footer hint
  if (footerHint) {
    footerHint.textContent = `鼠标移到屏幕${CORNER_LABELS[currentCorner]}唤起 · 离开自动收起`;
  }
}

async function loadSettings() {
  const settings = await window.api.getSettings();
  currentCorner = settings?.cornerTrigger || 'top-left';
  updateCornerUI();
  // Apply slide direction to panel immediately
  applySide(currentCorner.endsWith('-right') ? 'right' : 'left');
}

function applySide(side) {
  if (side === 'right') {
    panel.classList.add('side-right');
  } else {
    panel.classList.remove('side-right');
  }
}

btnSettings.addEventListener('click', (e) => {
  e.stopPropagation();
  settingsPopover.classList.toggle('hidden');
});

document.querySelectorAll('.corner-btn').forEach(btn => {
  btn.addEventListener('click', async (e) => {
    e.stopPropagation();
    const corner = btn.dataset.corner;
    if (corner === currentCorner) return;
    currentCorner = corner;
    await window.api.updateSettings({ cornerTrigger: corner });
    updateCornerUI();
    applySide(corner.endsWith('-right') ? 'right' : 'left');
  });
});

// Close settings popover when clicking outside
document.addEventListener('click', (e) => {
  if (!settingsPopover.contains(e.target) && !btnSettings.contains(e.target)) {
    settingsPopover.classList.add('hidden');
  }
});

// Listen for panel side changes from main process (e.g. display metrics changed)
window.api.onPanelSide((side) => applySide(side));

loadSettings();
