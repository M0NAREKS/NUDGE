const admin = require('firebase-admin');
const { callGroqChat } = require('./groq_client');

function parseJsonOrFallback(raw) {
  try {
    return JSON.parse(raw);
  } catch (_) {
    return {
      workouts: [],
      difficulty: 'unknown',
      duration: 'unknown',
      note: raw.trim(),
    };
  }
}

async function buildTrainingPlan(uid) {
  const userDoc = await admin.firestore().collection('users').doc(uid).get();
  const profile = userDoc.data() || {};
  const sevenDaysAgo = admin.firestore.Timestamp.fromDate(
    new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)
  );
  const mealsSnap = await admin
    .firestore()
    .collectionGroup('meals')
    .where('createdAt', '>=', sevenDaysAgo)
    .get();
  const meals = mealsSnap.docs.map((doc) => doc.data());

  const prompt = [
    'This worker is internal-only and not part of the public HTTP API.',
    `Profile: ${JSON.stringify(profile)}`,
    `LastMeals: ${JSON.stringify(meals.slice(0, 20))}`,
    'Generate workout plan JSON with workouts array (name, sets, reps), difficulty and duration.',
  ].join(' ');

  const content = await callGroqChat({
    apiKey: process.env.GROQ_API_KEY,
    modelKind: 'training',
    temperature: 0.3,
    responseFormat: { type: 'json_object' },
    messages: [
      { role: 'system', content: 'Fitness coach that outputs JSON only.' },
      { role: 'user', content: prompt },
    ],
  });

  const plan = parseJsonOrFallback(content);
  await admin
    .firestore()
    .collection('users')
    .doc(uid)
    .collection('ai')
    .doc('training_plan')
    .set(plan);
}

module.exports = { buildTrainingPlan };
