const STORAGE_KEYS = {
  baseUrl: 'petpal.admin.baseUrl',
  token: 'petpal.admin.token'
};

const defaultSettings = {
  baseUrl: 'http://127.0.0.1:8080',
  adminToken: ''
};

const state = {
  currentView: 'providers',
  providerSearch: '',
  providerStatus: 'ALL',
  appointmentStatus: 'ALL',
  editingProviderId: null,
  providers: [],
  serviceGroups: [],
  appointments: [],
  loading: false,
  banner: '',
  bannerTone: 'info',
  settings: loadSettings()
};

const els = {
  metrics: document.getElementById('metrics'),
  viewTitle: document.getElementById('view-title'),
  providerList: document.getElementById('provider-list'),
  serviceGroups: document.getElementById('service-groups'),
  appointmentList: document.getElementById('appointment-list'),
  providerSearch: document.getElementById('provider-search'),
  providerStatusFilter: document.getElementById('provider-status-filter'),
  appointmentStatusFilter: document.getElementById('appointment-status-filter'),
  providerDialog: document.getElementById('provider-dialog'),
  providerDialogTitle: document.getElementById('provider-dialog-title'),
  providerForm: document.getElementById('provider-form'),
  settingsForm: document.getElementById('settings-form'),
  apiBaseUrl: document.getElementById('api-base-url'),
  adminToken: document.getElementById('admin-token'),
  connectionStatus: document.getElementById('connection-status'),
  apiMode: document.getElementById('api-mode'),
  appBanner: document.getElementById('app-banner'),
  refreshButton: document.getElementById('refresh-button'),
  addProviderButton: document.getElementById('add-provider-button'),
  closeProviderDialog: document.getElementById('close-provider-dialog'),
  cancelProviderDialog: document.getElementById('cancel-provider-dialog')
};

const viewTitles = {
  providers: 'Provider Management',
  services: 'Service Groups',
  appointments: 'Appointment Operations'
};

function loadSettings() {
  try {
    return {
      baseUrl: localStorage.getItem(STORAGE_KEYS.baseUrl) || defaultSettings.baseUrl,
      adminToken: localStorage.getItem(STORAGE_KEYS.token) || defaultSettings.adminToken
    };
  } catch {
    return { ...defaultSettings };
  }
}

function saveSettings(settings) {
  try {
    localStorage.setItem(STORAGE_KEYS.baseUrl, settings.baseUrl);
    localStorage.setItem(STORAGE_KEYS.token, settings.adminToken);
  } catch {
    // Ignore storage failures and keep the current in-memory settings.
  }
}

function normalizeBaseUrl(value) {
  const trimmed = String(value || '').trim();
  if (!trimmed) {
    return defaultSettings.baseUrl;
  }
  return trimmed.replace(/\/+$/, '');
}

function apiUrl(path) {
  const baseUrl = normalizeBaseUrl(state.settings.baseUrl);
  const suffix = path.startsWith('/') ? path : `/${path}`;
  return `${baseUrl}${suffix}`;
}

function setBanner(message, tone = 'info') {
  state.banner = message;
  state.bannerTone = tone;
  if (!message) {
    els.appBanner.hidden = true;
    els.appBanner.textContent = '';
    els.appBanner.className = 'status-banner';
    return;
  }
  els.appBanner.hidden = false;
  els.appBanner.textContent = message;
  els.appBanner.className = `status-banner is-${tone}`;
}

function setLoading(loading) {
  state.loading = loading;
  els.refreshButton.disabled = loading;
  els.addProviderButton.disabled = loading;
  renderConnectionStatus();
}

function renderConnectionStatus() {
  const baseUrl = normalizeBaseUrl(state.settings.baseUrl);
  els.connectionStatus.textContent = state.settings.adminToken
    ? `Configured for ${baseUrl} with admin token`
    : `Configured for ${baseUrl} without admin token`;
  els.apiMode.textContent = state.loading ? 'Syncing' : 'Ready';
}

function renderViews() {
  document.querySelectorAll('.view').forEach((node) => {
    node.classList.toggle('is-active', node.id === `${state.currentView}-view`);
  });
  document.querySelectorAll('.nav-item').forEach((node) => {
    node.classList.toggle('is-active', node.dataset.view === state.currentView);
  });
  els.viewTitle.textContent = viewTitles[state.currentView];
}

function renderMetrics() {
  const pendingCount = state.appointments.filter((item) => item.status === 'PENDING_CONFIRM').length;
  const openCount = state.providers.filter((item) => item.status === 'OPEN').length;
  els.metrics.innerHTML = [
    metricCard('Providers', state.providers.length),
    metricCard('Open today', openCount),
    metricCard('Pending', pendingCount),
    metricCard('Appointments', state.appointments.length)
  ].join('');
}

function metricCard(label, value) {
  return `<article class="metric-card"><span>${label}</span><strong>${value}</strong></article>`;
}

function providerStatusChip(status) {
  return `<span class="chip">${status}</span>`;
}

function appointmentActions(item) {
  if (item.status === 'PENDING_CONFIRM') {
    return [
      actionButton(item.id, 'CONFIRMED', 'Confirm'),
      actionButton(item.id, 'CANCELLED', 'Cancel')
    ].join('');
  }
  if (item.status === 'CONFIRMED') {
    return [
      actionButton(item.id, 'COMPLETED', 'Complete'),
      actionButton(item.id, 'CANCELLED', 'Cancel')
    ].join('');
  }
  return '<span class="muted-inline">No actions</span>';
}

function actionButton(id, status, label) {
  return `<button class="ghost-button" data-action="update-status" data-id="${id}" data-status="${status}">${label}</button>`;
}

function openProviderDialog(provider) {
  state.editingProviderId = provider?.id ?? null;
  els.providerDialogTitle.textContent = provider ? 'Edit provider' : 'Add provider';
  els.providerForm.name.value = provider?.name ?? '';
  els.providerForm.type.value = provider?.type ?? 'HOSPITAL';
  els.providerForm.phone.value = provider?.phone ?? '';
  els.providerForm.status.value = provider?.status ?? 'OPEN';
  els.providerForm.address.value = provider?.address ?? '';
  els.providerForm.rating.value = provider?.rating ?? '4.5';
  els.providerForm.businessHours.value = provider?.businessHours ?? '09:00-20:00';
  els.providerDialog.showModal();
}

async function requestJson(path, options = {}) {
  const url = apiUrl(path);
  const headers = {
    Accept: 'application/json',
    'Content-Type': 'application/json',
    ...(options.headers || {})
  };
  if (state.settings.adminToken) {
    headers['X-PetPal-Admin-Token'] = state.settings.adminToken;
  }

  const response = await fetch(url, {
    method: options.method || 'GET',
    headers,
    body: options.body === undefined ? undefined : JSON.stringify(options.body)
  });

  const rawText = await response.text();
  let payload;
  try {
    payload = rawText ? JSON.parse(rawText) : null;
  } catch {
    payload = null;
  }

  if (!response.ok) {
    const message = payload?.message || payload?.msg || `HTTP ${response.status}`;
    throw new Error(message);
  }
  if (!payload) {
    throw new Error('Empty server response');
  }
  if (payload.code && payload.code !== 'OK') {
    throw new Error(payload.message || 'Request failed');
  }
  return Object.prototype.hasOwnProperty.call(payload, 'data') ? payload.data : payload;
}

function mapProvider(item) {
  return {
    id: item.id,
    name: item.name,
    type: item.type,
    address: item.address,
    phone: item.phone || '',
    rating: item.rating,
    status: item.status,
    businessHours: item.businessHours || item.business_hours || '',
    coverUrl: item.coverUrl || item.cover_url || ''
  };
}

function mapAppointment(item) {
  return {
    id: item.id,
    orderNo: item.orderNo || item.order_no,
    userId: item.userId || item.user_id,
    petId: item.petId || item.pet_id,
    petName: item.petName || item.pet_name,
    providerId: item.providerId || item.provider_id,
    providerName: item.providerName || item.provider_name,
    serviceId: item.serviceId || item.service_id,
    serviceName: item.serviceName || item.service_name,
    status: item.status,
    appointmentTime: item.appointmentTime || item.appointment_time,
    remark: item.remark || ''
  };
}

function mapService(item) {
  return {
    id: item.id,
    providerId: item.providerId || item.provider_id,
    name: item.name,
    price: item.price,
    durationMinutes: item.durationMinutes || item.duration_minutes || item.duration
  };
}

async function loadProviders() {
  const providers = await requestJson('/admin/providers');
  state.providers = providers.map(mapProvider);
}

async function loadAppointments() {
  const appointments = await requestJson('/admin/appointments');
  state.appointments = appointments.map(mapAppointment);
}

async function loadServiceGroups() {
  const groups = await Promise.all(
    state.providers.map(async (provider) => {
      const services = await requestJson(`/api/provider/${provider.id}/services`);
      return {
        providerId: provider.id,
        providerName: provider.name,
        services: services.map(mapService)
      };
    })
  );
  state.serviceGroups = groups;
}

function emptyState(message) {
  return `<article class="empty-state">${message}</article>`;
}

async function renderProviders() {
  const filtered = state.providers.filter((item) => {
    const matchesSearch = `${item.name} ${item.address}`.toLowerCase().includes(state.providerSearch.toLowerCase());
    const matchesStatus = state.providerStatus === 'ALL' || item.status === state.providerStatus;
    return matchesSearch && matchesStatus;
  });

  els.providerList.innerHTML = filtered.length > 0
    ? filtered.map((item) => `
      <article class="provider-card">
        <header>
          <div>
            <h4>${item.name}</h4>
            <p>${item.address}</p>
          </div>
          ${providerStatusChip(item.status)}
        </header>
        <div class="meta">
          <span class="chip">${item.type}</span>
          <span class="chip">Rating ${item.rating}</span>
          <span class="chip">${item.businessHours}</span>
        </div>
        <p>${item.phone || 'No phone'}</p>
        <div class="actions">
          <button class="ghost-button" data-action="edit-provider" data-id="${item.id}">Edit</button>
        </div>
      </article>
    `).join('')
    : emptyState('No providers found');
}

async function renderServiceGroups() {
  els.serviceGroups.innerHTML = state.serviceGroups.length > 0
    ? state.serviceGroups.map((group) => `
      <article class="service-card">
        <header>
          <h4>${group.providerName}</h4>
          <span class="chip">/api/provider/${group.providerId}/services</span>
        </header>
        <ul>
          ${group.services.map((service) => `<li>${service.name} - RMB ${service.price} - ${service.durationMinutes} min</li>`).join('')}
        </ul>
      </article>
    `).join('')
    : emptyState('No service groups found');
}

async function renderAppointments() {
  const filtered = state.appointments.filter((item) => state.appointmentStatus === 'ALL' || item.status === state.appointmentStatus);
  els.appointmentList.innerHTML = filtered.length > 0
    ? filtered.map((item) => `
      <tr>
        <td>${item.orderNo}</td>
        <td>User #${item.userId}<br>${item.petName}</td>
        <td>${item.providerName}<br>${item.serviceName}</td>
        <td>${item.appointmentTime}</td>
        <td><span class="chip">${item.status}</span></td>
        <td>${item.remark || ''}</td>
        <td class="actions">${appointmentActions(item)}</td>
      </tr>
    `).join('')
    : `<tr><td colspan="7">${emptyStateText('No appointments found')}</td></tr>`;
}

function emptyStateText(message) {
  return message;
}

async function refreshAll() {
  setLoading(true);
  setBanner('', 'info');
  const errors = [];

  try {
    await loadProviders();
  } catch (error) {
    errors.push(`Providers: ${error instanceof Error ? error.message : String(error)}`);
  }

  try {
    await loadAppointments();
  } catch (error) {
    errors.push(`Appointments: ${error instanceof Error ? error.message : String(error)}`);
  }

  try {
    await loadServiceGroups();
  } catch (error) {
    errors.push(`Services: ${error instanceof Error ? error.message : String(error)}`);
  }

  renderMetrics();
  renderViews();
  await Promise.all([renderProviders(), renderServiceGroups(), renderAppointments()]);

  if (errors.length > 0) {
    setBanner(errors.join(' | '), 'error');
  } else {
    setBanner(`Connected to ${normalizeBaseUrl(state.settings.baseUrl)}`, 'success');
  }

  setLoading(false);
}

async function updateAppointmentStatus(id, status) {
  await requestJson(`/admin/appointments/${id}/status`, {
    method: 'PUT',
    body: { status }
  });
  await refreshAll();
}

async function saveProvider(payload) {
  const path = state.editingProviderId ? `/admin/providers/${state.editingProviderId}` : '/admin/providers';
  const method = state.editingProviderId ? 'PUT' : 'POST';
  await requestJson(path, { method, body: payload });
}

function applySettingsFromForm() {
  const nextSettings = {
    baseUrl: normalizeBaseUrl(els.apiBaseUrl.value),
    adminToken: String(els.adminToken.value || '').trim()
  };
  state.settings = nextSettings;
  saveSettings(nextSettings);
  renderConnectionStatus();
}

function syncSettingsForm() {
  els.apiBaseUrl.value = state.settings.baseUrl;
  els.adminToken.value = state.settings.adminToken;
}

document.querySelectorAll('.nav-item').forEach((node) => {
  node.addEventListener('click', () => {
    state.currentView = node.dataset.view;
    renderViews();
  });
});

document.getElementById('refresh-button').addEventListener('click', async () => {
  await refreshAll();
});

document.getElementById('add-provider-button').addEventListener('click', () => openProviderDialog());
els.closeProviderDialog.addEventListener('click', () => els.providerDialog.close());
els.cancelProviderDialog.addEventListener('click', () => els.providerDialog.close());

els.settingsForm.addEventListener('submit', async (event) => {
  event.preventDefault();
  applySettingsFromForm();
  await refreshAll();
});

els.providerSearch.addEventListener('input', async (event) => {
  state.providerSearch = event.target.value;
  await renderProviders();
});

els.providerStatusFilter.addEventListener('change', async (event) => {
  state.providerStatus = event.target.value;
  await renderProviders();
});

els.appointmentStatusFilter.addEventListener('change', async (event) => {
  state.appointmentStatus = event.target.value;
  await renderAppointments();
});

els.providerList.addEventListener('click', (event) => {
  const target = event.target.closest('[data-action="edit-provider"]');
  if (!target) {
    return;
  }
  const provider = state.providers.find((item) => item.id === Number(target.dataset.id));
  openProviderDialog(provider);
});

els.appointmentList.addEventListener('click', async (event) => {
  const target = event.target.closest('[data-action="update-status"]');
  if (!target) {
    return;
  }
  try {
    setBanner('', 'info');
    await updateAppointmentStatus(Number(target.dataset.id), target.dataset.status);
    setBanner(`Appointment ${target.dataset.id} updated to ${target.dataset.status}`, 'success');
  } catch (error) {
    setBanner(error instanceof Error ? error.message : String(error), 'error');
  }
});

els.providerForm.addEventListener('submit', async (event) => {
  event.preventDefault();
  const payload = {
    name: els.providerForm.name.value.trim(),
    type: els.providerForm.type.value,
    phone: els.providerForm.phone.value.trim(),
    status: els.providerForm.status.value,
    address: els.providerForm.address.value.trim(),
    rating: Number(els.providerForm.rating.value),
    businessHours: els.providerForm.businessHours.value.trim(),
    coverUrl: 'https://placehold.co/800x400'
  };

  try {
    setBanner('', 'info');
    await saveProvider(payload);
    els.providerDialog.close();
    state.editingProviderId = null;
    setBanner('Provider saved', 'success');
    await refreshAll();
  } catch (error) {
    setBanner(error instanceof Error ? error.message : String(error), 'error');
  }
});

function init() {
  syncSettingsForm();
  renderConnectionStatus();
  renderViews();
  refreshAll();
}

init();
