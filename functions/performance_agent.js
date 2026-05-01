const admin = require('firebase-admin');
const { callGroqChat } = require('./groq_client');

function parseJsonOrFallback(raw) {
  try {
    return JSON.parse(raw);
  } catch (_) {
    return {
      trend: 'unknown',
      recommendations: [],
      note: raw.trim(),
    };
  }
}

async function buildPerformanceReport(uid) {
  const twoWeeksAgo = admin.firestore.Timestamp.fromDate(
    new Date(Date.now() - 14 * 24 * 60 * 60 * 1000)
  );
  const nutritionSnap = await admin
    .firestore()
    .collectionGroup('nutrition')
    .where('createdAt', '>=', twoWeeksAgo)
    .limit(50)
    .get();
  const dataPoints = nutritionSnap.docs.map((doc) => doc.data());

  const prompt = [
    'This worker is internal-only and not part of the public HTTP API.',
    `Analyse trends for last 14 days: ${JSON.stringify(dataPoints)}.`,
    'Provide JSON {trend:string, recommendations:string[]}.',
  ].join(' ');

  const content = await callGroqChat({
    apiKey: process.env.GROQ_API_KEY,
    modelKind: 'performance',
    temperature: 0.2,
    responseFormat: { type: 'json_object' },
    messages: [
      { role: 'system', content: 'Performance analyst returning JSON only.' },
      { role: 'user', content: prompt },
    ],
  });

  const report = parseJsonOrFallback(content);
  await admin
    .firestore()
    .collection('users')
    .doc(uid)
    .collection('ai')
    .doc('performance_report')
    .set(report);
}

module.exports = { buildPerformanceReport };
