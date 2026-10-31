// Caregiver notifications: (1) unconfirmed dose after 30 min, (2) low / out of stock.
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { onDocumentUpdated } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

const GRACE_MS = 30 * 60 * 1000;
const STALE_MS = 6 * 60 * 60 * 1000; // never notify about doses older than this
const CHANNEL = 'caregiver_alerts_v2'; // created by the app (NotificationService)

async function notifyCaregiver(elderUid, item, push) {
  const link = await db.collection('careLinks').doc(elderUid).get();
  if (!link.exists) return false; // nobody to notify
  const { caregiverUid, elderName = '' } = link.data();

  const userRef = db.collection('users').doc(caregiverUid);
  await userRef.collection('notifications').add({
    ...item,
    personName: elderName,
    createdAt: Date.now(),
  });

  const tokens = ((await userRef.get()).data() || {}).fcmTokens || [];
  if (tokens.length === 0) return true;

  const res = await admin.messaging().sendEachForMulticast({
    tokens,
    notification: { title: push.title, body: push.body(elderName) },
    data: { type: item.type },
    android: { priority: 'high', notification: { channelId: CHANNEL, sound: 'default' } },
    apns: { headers: { 'apns-priority': '10' }, payload: { aps: { sound: 'default' } } },
  });

  // Remove tokens of uninstalled / signed-out devices.
  const dead = [];
  res.responses.forEach((r, i) => {
    const code = r.error && r.error.code;
    if (code === 'messaging/registration-token-not-registered' ||
        code === 'messaging/invalid-registration-token') dead.push(tokens[i]);
  });
  if (dead.length) {
    await userRef.update({ fcmTokens: admin.firestore.FieldValue.arrayRemove(...dead) });
  }
  return true;
}

// Every 5 minutes: pending doses older than 30 minutes -> missed + notify ONCE.
exports.detectUnconfirmedDoses = onSchedule('every 5 minutes', async () => {
  const cutoff = Date.now() - GRACE_MS;
  const snap = await db.collectionGroup('doseLogs')
    .where('status', '==', 'pending')
    .where('notifiedMissed', '==', false)
    .where('scheduledAt', '<=', cutoff)
    .limit(200)
    .get();

  for (const doc of snap.docs) {
    try {
      // Claim the document atomically so overlapping runs never notify twice.
      const claimed = await db.runTransaction(async (tx) => {
        const s = await tx.get(doc.ref);
        if (!s.exists || s.data().status !== 'pending' || s.data().notifiedMissed === true) return false;
        tx.update(doc.ref, { status: 'missed', notifiedMissed: true });
        return true;
      });
      if (!claimed) continue;

      const d = doc.data();
      if (Date.now() - d.scheduledAt > STALE_MS) continue; // too old: record only
      const owner = doc.ref.path.split('/')[1]; // users/{owner}/profiles/{pid}/doseLogs/{id}
      await notifyCaregiver(
        owner,
        { type: 'missed_dose', medicationName: d.medicationName, scheduledAt: d.scheduledAt, amount: d.amount },
        {
          title: 'جرعة غير مؤكدة / Unconfirmed dose',
          body: (name) => `${name}: ${d.medicationName}`,
        },
      );
    } catch (e) {
      console.error('detectUnconfirmedDoses failed for', doc.ref.path, e);
    }
  }
});

// Stock crossed the alert threshold (or reached zero).
exports.onStockChange = onDocumentUpdated(
  'users/{uid}/profiles/{pid}/medications/{mid}',
  async (event) => {
    const before = event.data && event.data.before.data();
    const after = event.data && event.data.after.data();
    if (!before || !after || before.remaining === after.remaining) return;

    const threshold = after.alertThreshold ?? 5;
    const hitZero = before.remaining > 0 && after.remaining <= 0;
    const crossedLow = before.remaining > threshold && after.remaining <= threshold && after.remaining > 0;
    if (!crossedLow && !hitZero) return;

    await notifyCaregiver(
      event.params.uid,
      {
        type: hitZero ? 'out_of_stock' : 'low_stock',
        medicationName: after.name,
        remaining: after.remaining,
        threshold,
      },
      {
        title: hitZero ? 'نفد الدواء / Out of stock' : 'الدواء أوشك على النفاد / Running low',
        body: (name) => `${name}: ${after.name} (${after.remaining})`,
      },
    );
  },
);
