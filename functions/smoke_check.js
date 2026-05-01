const BASE_URL =
  process.env.FITCOACH_FUNCTIONS_BASE_URL ||
  'https://us-central1-fitcoach-13e40.cloudfunctions.net';
const ORIGIN = process.env.FITCOACH_SMOKE_ORIGIN || 'http://localhost:61636';
const ID_TOKEN = (process.env.FITCOACH_ID_TOKEN || '').trim();

async function request(path, options = {}) {
  const response = await fetch(`${BASE_URL}/${path}`, options);
  const text = await response.text();
  let json = null;
  try {
    json = text ? JSON.parse(text) : null;
  } catch (_) {
    json = null;
  }

  return { response, text, json };
}

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

async function checkPreflight(path, method) {
  const { response } = await request(path, {
    method: 'OPTIONS',
    headers: {
      Origin: ORIGIN,
      'Access-Control-Request-Method': method,
      'Access-Control-Request-Headers': 'authorization,content-type',
    },
  });

  assert(response.status === 204, `${path} preflight failed with ${response.status}`);
  assert(
    response.headers.get('access-control-allow-origin') === ORIGIN,
    `${path} preflight missing reflected origin`
  );
}

async function checkUnauth(path, method, body) {
  const { response, json } = await request(path, {
    method,
    headers: {
      Origin: ORIGIN,
      ...(body ? { 'Content-Type': 'application/json' } : {}),
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });

  assert(response.status === 401, `${path} unauth expected 401, got ${response.status}`);
  assert(json?.error === true, `${path} unauth response missing error envelope`);
  assert(typeof json?.code === 'string', `${path} unauth response missing code`);
  assert(typeof json?.message === 'string', `${path} unauth response missing message`);
}

async function checkHappyPath(path, method, body) {
  if (!ID_TOKEN) {
    console.log(`- ${path}: happy-path skipped (FITCOACH_ID_TOKEN missing)`);
    return;
  }

  const { response, json } = await request(path, {
    method,
    headers: {
      Origin: ORIGIN,
      Authorization: `Bearer ${ID_TOKEN}`,
      ...(body ? { 'Content-Type': 'application/json' } : {}),
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });

  assert(response.status >= 200 && response.status < 300, `${path} happy-path failed`);
  assert(json && typeof json === 'object', `${path} happy-path missing JSON body`);
}

async function main() {
  console.log(`FitCoach API smoke check`);
  console.log(`Base URL: ${BASE_URL}`);
  console.log(`Origin: ${ORIGIN}`);

  await checkPreflight('fatsecretSearch?q=apple', 'GET');
  await checkPreflight('foodEstimate', 'POST');
  await checkPreflight('dailyNarrative', 'POST');
  await checkPreflight('coachChat', 'POST');

  await checkUnauth('fatsecretSearch?q=apple', 'GET');
  await checkUnauth('foodEstimate', 'POST', { query: 'apple' });
  await checkUnauth('dailyNarrative', 'POST', {
    locale: 'tr',
    insight: {
      consistencyScore: 70,
      positiveSignal: 'Protein iyi.',
      riskSignal: 'Su dusuk.',
      tomorrowAction: 'Bir sise su ekle.',
    },
  });
  await checkUnauth('coachChat', 'POST', { content: 'test', mode: 'balanced coach' });

  await checkHappyPath('fatsecretSearch?q=apple', 'GET');
  await checkHappyPath('foodEstimate', 'POST', { query: '1 bowl yogurt' });
  await checkHappyPath('dailyNarrative', 'POST', {
    locale: 'tr',
    insight: {
      consistencyScore: 70,
      positiveSignal: 'Protein iyi.',
      riskSignal: 'Su dusuk.',
      tomorrowAction: 'Bir sise su ekle.',
      recoveryMode: false,
    },
  });
  await checkHappyPath('coachChat', 'POST', {
    content: 'Bugun ne yemeliyim?',
    mode: 'balanced coach',
  });

  console.log('Smoke check tamamlandi.');
}

main().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
