const db = {
  providers: [
    { id: 1, name: 'Cloud Vet Center', type: 'HOSPITAL', address: 'Pudong Dingxiang Rd 188', phone: '021-88880001', rating: 4.8, status: 'OPEN', businessHours: '09:00-21:00' },
    { id: 2, name: 'Bubble Grooming', type: 'GROOMING', address: 'Jingan Wanhangdu Rd 520', phone: '021-88880002', rating: 4.6, status: 'PAUSED', businessHours: '10:00-20:00' },
    { id: 3, name: 'Forest Boarding', type: 'BOARDING', address: 'Minhang Lianhua South Rd 999', phone: '021-88880003', rating: 4.9, status: 'OPEN', businessHours: '00:00-24:00' }
  ],
  serviceGroups: [
    { providerId: 1, providerName: 'Cloud Vet Center', services: [{ id: 101, name: 'Routine Checkup', price: 199, duration: 30 }, { id: 102, name: 'Vaccination', price: 120, duration: 20 }] },
    { providerId: 2, providerName: 'Bubble Grooming', services: [{ id: 201, name: 'Basic Bath', price: 99, duration: 60 }, { id: 202, name: 'Full Grooming', price: 238, duration: 120 }] },
    { providerId: 3, providerName: 'Forest Boarding', services: [{ id: 301, name: 'Day Boarding', price: 168, duration: 480 }, { id: 302, name: 'Overnight Boarding', price: 298, duration: 1440 }] }
  ],
  appointments: [
    { id: 5001, orderNo: 'PP202603260001', userName: 'Lin Yi', petName: 'Pudding', providerName: 'Cloud Vet Center', serviceName: 'Routine Checkup', appointmentTime: '2026-03-27 10:30', status: 'PENDING_CONFIRM', remark: 'Recent appetite drop' },
    { id: 5002, orderNo: 'PP202603260002', userName: 'Zhou Ning', petName: 'Snowball', providerName: 'Bubble Grooming', serviceName: 'Full Grooming', appointmentTime: '2026-03-27 14:00', status: 'CONFIRMED', remark: 'Sensitive to dryers' },
    { id: 5003, orderNo: 'PP202603260003', userName: 'Xu Yan', petName: 'Latte', providerName: 'Forest Boarding', serviceName: 'Overnight Boarding', appointmentTime: '2026-03-28 19:00', status: 'COMPLETED', remark: 'Bring own food' }
  ]
};

const state = {
  currentView: 'providers',
  providerSearch: '',
  providerStatus: 'ALL',
  appointmentStatus: 'ALL',
  editingProviderId: null
};

const api = {
  listProviders() {
    return Promise.resolve([...db.providers]);
  },
  upsertProvider(payload) {
    if (payload.id) {
      db.providers = db.providers.map((item) => item.id === payload.id ? payload : item);
    } else {
      payload.id = Date.now();
      db.providers = [payload, ...db.providers];
    }
    return Promise.resolve(payload);
  },
  listServiceGroups() {
    return Promise.resolve([...db.serviceGroups]);
  },
  listAppointments() {
    return Promise.resolve([...db.appointments]);
  },
  updateAppointmentStatus(id, status) {
    db.appointments = db.appointments.map((item) => item.id === id ? { ...item, status } : item);
    return Promise.resolve();
  }
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
  providerForm: document.getElementById('provider-form')
};

const viewTitles = {
  providers: 'Provider Management',
  services: 'Service Placeholder',
  appointments: 'Appointment Operations'
};

function renderMetrics() {
  const pendingCount = db.appointments.filter((item) => item.status === 'PENDING_CONFIRM').length;
  const openCount = db.providers.filter((item) => item.status === 'OPEN').length;
  els.metrics.innerHTML = [
    metricCard('Providers', db.providers.length),
    metricCard('Open today', openCount),
    metricCard('Pending', pendingCount),
    metricCard('Appointments', db.appointments.length)
  ].join('');
}

function metricCard(label, value) {
  return `<article class="metric-card"><span>${label}</span><strong>${value}</strong></article>`;
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

async function renderProviders() {
  const list = await api.listProviders();
  const filtered = list.filter((item) => {
    const matchesSearch = `${item.name} ${item.address}`.toLowerCase().includes(state.providerSearch.toLowerCase());
    const matchesStatus = state.providerStatus === 'ALL' || item.status === state.providerStatus;
    return matchesSearch && matchesStatus;
  });

  els.providerList.innerHTML = filtered.map((item) => `
    <article class="provider-card">
      <header>
        <div>
          <h4>${item.name}</h4>
          <p>${item.address}</p>
        </div>
        <span class="chip">${item.status}</span>
      </header>
      <div class="meta">
        <span class="chip">${item.type}</span>
        <span class="chip">Rating ${item.rating}</span>
        <span class="chip">${item.businessHours}</span>
      </div>
      <p>${item.phone}</p>
      <div class="actions">
        <button class="ghost-button" data-action="edit-provider" data-id="${item.id}">Edit</button>
      </div>
    </article>
  `).join('');
}

async function renderServiceGroups() {
  const groups = await api.listServiceGroups();
  els.serviceGroups.innerHTML = groups.map((group) => `
    <article class="service-card">
      <header>
        <h4>${group.providerName}</h4>
        <span class="chip">GET /admin/providers/${group.providerId}/services</span>
      </header>
      <ul>
        ${group.services.map((service) => `<li>${service.name} - USD ${service.price} - ${service.duration} min</li>`).join('')}
      </ul>
    </article>
  `).join('');
}

async function renderAppointments() {
  const list = await api.listAppointments();
  const filtered = list.filter((item) => state.appointmentStatus === 'ALL' || item.status === state.appointmentStatus);
  els.appointmentList.innerHTML = filtered.map((item) => `
    <tr>
      <td>${item.orderNo}</td>
      <td>${item.userName}<br>${item.petName}</td>
      <td>${item.providerName}<br>${item.serviceName}</td>
      <td>${item.appointmentTime}</td>
      <td><span class="chip">${item.status}</span></td>
      <td>${item.remark}</td>
      <td class="actions">
        ${statusAction(item.id, 'CONFIRMED', 'Confirm')}
        ${statusAction(item.id, 'COMPLETED', 'Complete')}
        ${statusAction(item.id, 'CANCELLED', 'Cancel')}
      </td>
    </tr>
  `).join('');
}

function statusAction(id, status, label) {
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

async function renderAll() {
  renderMetrics();
  renderViews();
  await Promise.all([renderProviders(), renderServiceGroups(), renderAppointments()]);
}

document.querySelectorAll('.nav-item').forEach((node) => {
  node.addEventListener('click', async () => {
    state.currentView = node.dataset.view;
    renderViews();
  });
});

document.getElementById('refresh-button').addEventListener('click', renderAll);
document.getElementById('add-provider-button').addEventListener('click', () => openProviderDialog());
document.getElementById('close-provider-dialog').addEventListener('click', () => els.providerDialog.close());
document.getElementById('cancel-provider-dialog').addEventListener('click', () => els.providerDialog.close());

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
  const provider = db.providers.find((item) => item.id === Number(target.dataset.id));
  openProviderDialog(provider);
});

els.appointmentList.addEventListener('click', async (event) => {
  const target = event.target.closest('[data-action="update-status"]');
  if (!target) {
    return;
  }
  await api.updateAppointmentStatus(Number(target.dataset.id), target.dataset.status);
  await renderAll();
});

els.providerForm.addEventListener('submit', async (event) => {
  event.preventDefault();
  const payload = {
    id: state.editingProviderId,
    name: els.providerForm.name.value.trim(),
    type: els.providerForm.type.value,
    phone: els.providerForm.phone.value.trim(),
    status: els.providerForm.status.value,
    address: els.providerForm.address.value.trim(),
    rating: Number(els.providerForm.rating.value),
    businessHours: els.providerForm.businessHours.value.trim()
  };
  await api.upsertProvider(payload);
  els.providerDialog.close();
  await renderAll();
});

renderAll();
