// Caregiver notifications: (1) unconfirmed dose after 30 min, (2) low / out of stock.
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { onDocumentUpdated } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();
const GRACE_MS = 30 * 60 * 1000;

async function notifyCaregiver(elderUid, item, push) {
  const link = await db.collection('careLinks').doc(elderUid).get();
  if (!link.exists) return false; // nobody to notify
  const caregiverUid = link.data().caregiverUid;
  const personName = link.data().elderName || '';

  await db.collection('users').doc(caregiverUid).collection('notifications').add({
    ...item,
    personName,
    createdAt: Date.now(),
  });

  const user = await db.collection('users').doc(caregiverUid).get();
  const tokens = (user.data() || {}).fcmTokens || [];
  if (tokens.length) {
    await admin.messaging().sendEachForMulticast({
      tokens,
      notification: { title: push.title(personName), body: push.body(personName) },
    });
  }
  return true;
}

// Every 5 minutes: pending doses older than 30 min -> unconfirmed + notify once.
exports.detectUnconfirmedDoses = onSchedule('every 5 minutes', async () => {
  const cutoff = Date.now() - GRACE_MS;
  const snap = await db.collectionGroup('doseLogs')
    .where('status', '==', 'pending')
    .where('notifiedMissed', '==', false)
    .where('scheduledAt', '<=', cutoff)
    .limit(200)
    .get();

  for (const doc of snap.docs) {
    // path: users/{owner}/profiles/{pid}/doseLogs/{id}
    const owner = doc.ref.path.split('/')[1];
    const d = doc.data();
    await notifyCaregiver(
      owner,
      { type: 'missed_dose', medicationName: d.medicationName, scheduledAt: d.scheduledAt, amount: d.amount },
      {
        title: () => 'جرعة غير مؤكدة / Unconfirmed dose',
        body: (name) => `${name}: ${d.medicationName}`,
      },
    );
    await doc.ref.update({ status: 'missed', notifiedMissed: true });
  }
});

// Stock crossed the alert threshold (or reached zero).
exports.onStockChange = onDocumentUpdated(
  'users/{uid}/profiles/{pid}/medications/{mid}',
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    if (before.remaining === after.remaining) return;

    const threshold = after.alertThreshold ?? 5;
    const crossedLow = before.remaining > threshold && after.remaining <= threshold && after.remaining > 0;
    const hitZero = before.remaining > 0 && after.remaining <= 0;
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
        title: () => (hitZero ? 'نفد الدواء / Out of stock' : 'الدواء أوشك على النفاد / Running low'),
        body: (name) => `${name}: ${after.name} (${after.remaining})`,
      },
    );
  },
);
