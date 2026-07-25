#!/usr/bin/env node
/**
 * seeds CarePlus Firestore collections with sample documents
 *
 * Usage: node scripts/seed_firestore.js
 */

const fs = require('fs');
const os = require('os');
const path = require('path');
const https = require('https');

const PROJECT_ID = 'careplusplus-b8166';
const BASE = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

// User IDs: user_<increment> (user_001, user_002, ...)
const PATIENT_UID = 'user_001';
const PROVIDER_UID = 'user_002';
const PROVIDER_ID = 'prov_123';
const FACILITY_ID = 'fac_001';
const RECORD_ID = 'rec_001';
const VISIT_ID = 'visit_001';
const METRIC_ID = 'met_001';
const REMINDER_ID = 'rem_001';
const SESSION_ID = 'qr_001';

// legacy IDs to remove after rewrite
const LEGACY_DOCS = [
  ['users', 'auth_uid_monicah'],
  ['users', 'auth_uid_jane'],
  ['patient_profiles', 'auth_uid_monicah'],
];

function loadAccessToken() {
  const configPath = path.join(os.homedir(), '.config/configstore/firebase-tools.json');
  const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  const tokens = config.tokens;
  if (!tokens?.access_token) {
    throw new Error('no Firebase access token found');
  }
  if (tokens.expires_at && Date.now() > tokens.expires_at) {
    throw new Error('Firebase access token expired');
  }
  return tokens.access_token;
}

function stringValue(s) {
  return { stringValue: String(s) };
}
function boolValue(b) {
  return { booleanValue: Boolean(b) };
}
function intValue(n) {
  return { integerValue: String(n) };
}
function timestampValue(isoOrDate) {
  const d = isoOrDate instanceof Date ? isoOrDate : new Date(isoOrDate);
  return { timestampValue: d.toISOString() };
}
function arrayValue(values) {
  return { arrayValue: { values } };
}
function mapValue(fields) {
  return { mapValue: { fields } };
}
function stringArray(arr) {
  return arrayValue(arr.map(stringValue));
}

function request(method, url, token, body) {
  return new Promise((resolve, reject) => {
    const u = new URL(url);
    const opts = {
      hostname: u.hostname,
      path: u.pathname + u.search,
      method,
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
    };
    const req = https.request(opts, (res) => {
      let data = '';
      res.on('data', (c) => (data += c));
      res.on('end', () => {
        let parsed;
        try {
          parsed = data ? JSON.parse(data) : {};
        } catch {
          parsed = { raw: data };
        }
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(parsed);
        } else {
          reject(
            new Error(
              `${method} ${u.pathname} → ${res.statusCode}: ${JSON.stringify(parsed)}`
            )
          );
        }
      });
    });
    req.on('error', reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

async function upsertDoc(token, collection, docId, fields) {
  const url = `${BASE}/${collection}?documentId=${encodeURIComponent(docId)}`;
  try {
    await request('POST', url, token, { fields });
    console.log(`created ${collection}/${docId}`);
  } catch (err) {
    // if document already exist, we patch instead (full replace, no updateMask)
    if (String(err.message).includes('ALREADY_EXISTS') || String(err.message).includes('409')) {
      const patchUrl = `${BASE}/${collection}/${docId}`;
      await request('PATCH', patchUrl, token, { fields });
      console.log(`updated ${collection}/${docId}`);
    } else {
      throw err;
    }
  }
}

async function deleteDoc(token, collection, docId) {
  const url = `${BASE}/${collection}/${docId}`;
  try {
    await request('DELETE', url, token);
    console.log(`deleted ${collection}/${docId}`);
  } catch (err) {
    if (String(err.message).includes('404') || String(err.message).includes('NOT_FOUND')) {
      console.log(`skip missing ${collection}/${docId}`);
    } else {
      throw err;
    }
  }
}

async function main() {
  const token = loadAccessToken();
  const now = new Date();
  const nextWeek = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
  const tomorrow8am = new Date(now);
  tomorrow8am.setDate(tomorrow8am.getDate() + 1);
  tomorrow8am.setHours(8, 0, 0, 0);

  console.log(`seeding Firestore project: ${PROJECT_ID}`);
  console.log(`User IDs: ${PATIENT_UID} (patient), ${PROVIDER_UID} (provider)\n`);

  console.log('removing legacy auth_* docs...');
  for (const [collection, docId] of LEGACY_DOCS) {
    await deleteDoc(token, collection, docId);
  }
  console.log('');

  // --- users ---
  await upsertDoc(token, 'users', PATIENT_UID, {
    uid: stringValue(PATIENT_UID),
    fullName: stringValue('Monicah Moses'),
    email: stringValue('m.dhieu@alustudent.com'),
    phone: stringValue('+250795458141'),
    role: stringValue('patient'),
    createdAt: timestampValue(now),
    lastLogin: timestampValue(now),
    status: stringValue('active'),
  });

  await upsertDoc(token, 'users', PROVIDER_UID, {
    uid: stringValue(PROVIDER_UID),
    fullName: stringValue('Dr. Jane'),
    email: stringValue('dr.jane@careplus.rw'),
    phone: stringValue('+250780000001'),
    role: stringValue('provider'),
    createdAt: timestampValue(now),
    lastLogin: timestampValue(now),
    status: stringValue('active'),
  });

  // --- patient_profiles ---
  await upsertDoc(token, 'patient_profiles', PATIENT_UID, {
    patientId: stringValue(PATIENT_UID),
    dateOfBirth: stringValue('1990-01-01'),
    gender: stringValue('female'),
    bloodType: stringValue('O+'),
    allergies: stringArray(['penicillin']),
    conditions: stringArray(['hypertension']),
    emergencyContacts: arrayValue([
      mapValue({
        name: stringValue('Becky Annie'),
        phone: stringValue('+250780781688'),
        relation: stringValue('spouse'),
      }),
    ]),
    consentSettings: mapValue({
      shareWithProviders: boolValue(true),
      shareEmergencySummary: boolValue(true),
    }),
    preferredLanguage: stringValue('en'),
    address: stringValue('Kigali'),
  });

  // --- facilities ---
  await upsertDoc(token, 'facilities', FACILITY_ID, {
    facilityId: stringValue(FACILITY_ID),
    name: stringValue('Kigali Health Centre'),
    type: stringValue('clinic'),
    district: stringValue('Kigali'),
    province: stringValue('City of Kigali'),
    address: stringValue('KN 3 Rd, Kigali'),
    openMRSConnected: boolValue(false),
    active: boolValue(true),
  });

  // --- providers ---
  await upsertDoc(token, 'providers', PROVIDER_ID, {
    providerId: stringValue(PROVIDER_ID),
    userId: stringValue(PROVIDER_UID),
    facilityId: stringValue(FACILITY_ID),
    fullName: stringValue('Dr. Jane'),
    specialty: stringValue('internal medicine'),
    licenseNumber: stringValue('MED12345'),
    verified: boolValue(true),
  });

  // --- visits ---
  await upsertDoc(token, 'visits', VISIT_ID, {
    visitId: stringValue(VISIT_ID),
    patientId: stringValue(PATIENT_UID),
    providerId: stringValue(PROVIDER_ID),
    facilityId: stringValue(FACILITY_ID),
    visitDate: timestampValue(now),
    reasonForVisit: stringValue('routine checkup'),
    symptoms: stringArray(['headache']),
    diagnosis: stringArray(['hypertension']),
    notes: stringValue('clinical note'),
    followUpPlan: stringValue('return in 1 month'),
    synced: boolValue(false),
  });

  // --- records ---
  await upsertDoc(token, 'records', RECORD_ID, {
    recordId: stringValue(RECORD_ID),
    patientId: stringValue(PATIENT_UID),
    recordType: stringValue('visit-summary'),
    title: stringValue('Hypertension follow-up'),
    summary: stringValue('BP controlled'),
    details: stringValue('Structured clinical note'),
    sourceType: stringValue('provider'),
    sourceId: stringValue(VISIT_ID),
    visibility: stringValue('patient-and-provider'),
    tags: stringArray(['hypertension']),
    attachmentsRefs: stringArray(['attachments/path/file.pdf']),
    createdAt: timestampValue(now),
    updatedAt: timestampValue(now),
  });

  // --- metrics ---
  await upsertDoc(token, 'metrics', METRIC_ID, {
    metricId: stringValue(METRIC_ID),
    patientId: stringValue(PATIENT_UID),
    metricType: stringValue('bloodPressure'),
    value: stringValue('120/80'),
    unit: stringValue('mmHg'),
    measuredAt: timestampValue(now),
    source: stringValue('manual'),
    note: stringValue('morning reading'),
  });

  // --- reminders ---
  await upsertDoc(token, 'reminders', REMINDER_ID, {
    reminderId: stringValue(REMINDER_ID),
    patientId: stringValue(PATIENT_UID),
    type: stringValue('medication'),
    title: stringValue('Take Amlodipine'),
    message: stringValue('Take after breakfast'),
    schedule: mapValue({
      frequency: stringValue('daily'),
      time: stringValue('08:00'),
    }),
    timezone: stringValue('Africa/Kigali'),
    enabled: boolValue(true),
    relatedPrescriptionId: stringValue('rx_001'),
    nextRunAt: timestampValue(tomorrow8am),
  });

  // --- qr_sessions ---
  await upsertDoc(token, 'qr_sessions', SESSION_ID, {
    sessionId: stringValue(SESSION_ID),
    patientId: stringValue(PATIENT_UID),
    sessionType: stringValue('dynamic'),
    accessLevel: stringValue('read-only'),
    allowedRecords: stringArray([RECORD_ID, VISIT_ID]),
    generatedAt: timestampValue(now),
    expiresAt: timestampValue(nextWeek),
    revoked: boolValue(false),
    scannedByProviderId: stringValue(PROVIDER_ID),
    scanCount: intValue(1),
    emergencyMode: boolValue(false),
  });

  console.log('\nDone. Collections seeded:');
  console.log(
    [
      'users',
      'patient_profiles',
      'providers',
      'facilities',
      'records',
      'visits',
      'metrics',
      'reminders',
      'qr_sessions',
    ]
      .map((c) => `  - ${c}`)
      .join('\n')
  );
}

main().catch((err) => {
  console.error('\nSeed failed:', err.message);
  process.exit(1);
});
