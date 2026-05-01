const { onRequest } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const logger = require('firebase-functions/logger');
const admin = require('firebase-admin');
const axios = require('axios');

const { callGroqChat } = require('./groq_client');

if (!admin.apps.length) {
  admin.initializeApp();
}

const FATSECRET_CLIENT_ID = defineSecret('FATSECRET_CLIENT_ID');
const FATSECRET_CLIENT_SECRET = defineSecret('FATSECRET_CLIENT_SECRET');
const GROQ_API_KEY = defineSecret('GROQ_API_KEY');

let cachedFatSecretToken = null;
let fatSecretTokenExpiryMs = 0;

function setCors(req, res) {
  const origin = req.get('Origin');
  res.set('Vary', 'Origin');
  res.set('Access-Control-Allow-Origin', origin || '*');
  res.set('Access-Control-Allow-Headers', 'Authorization, Content-Type, X-Firebase-AppCheck');
  res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.set('Access-Control-Max-Age', '3600');
}

function sendError(res, status, code, message) {
  return res.status(status).json({
    error: true,
    code,
    message,
  });
}

function normalizeQuery(rawValue) {
  return (rawValue || '').toString().trim();
}

function resolveLocale(rawLocale) {
  return normalizeQuery(rawLocale).toLowerCase() === 'en' ? 'en' : 'tr';
}

function readLocale(req) {
  return resolveLocale(req.query?.locale || req.body?.locale);
}

function localizedText(locale, tr, en) {
  return locale === 'en' ? en : tr;
}

function secretValue(secretParam) {
  return (secretParam.value() || '').trim();
}

function extractBearerToken(req) {
  const authHeader = req.get('Authorization') || '';
  if (!authHeader.startsWith('Bearer ')) {
    return null;
  }

  return authHeader.slice('Bearer '.length).trim();
}

async function authenticateRequest(req, res) {
  const locale = readLocale(req);
  const token = extractBearerToken(req);
  if (!token) {
    sendError(
      res,
      401,
      'unauthenticated',
      localizedText(locale, 'Kimlik doğrulaması gerekli.', 'Authentication is required.')
    );
    return null;
  }

  try {
    return await admin.auth().verifyIdToken(token);
  } catch (error) {
    logger.warn(`Auth verification failed: ${error.message}`);
    sendError(
      res,
      401,
      'unauthenticated',
      localizedText(locale, 'Geçersiz oturum.', 'Invalid session.')
    );
    return null;
  }
}

function validateShortText(value, fieldName, locale) {
  if (!value) {
    return localizedText(
      locale,
      `${fieldName} gerekli.`,
      `${fieldName} is required.`
    );
  }

  if (value.length < 2) {
    return localizedText(
      locale,
      `${fieldName} çok kısa.`,
      `${fieldName} is too short.`
    );
  }

  if (!/[a-z0-9]/i.test(value)) {
    return localizedText(
      locale,
      `${fieldName} geçersiz.`,
      `${fieldName} is invalid.`
    );
  }

  return null;
}

function createHttpFunction({ method, secrets = [], name, handler }) {
  return onRequest(
    {
      region: 'us-central1',
      cors: false,
      secrets,
    },
    async (req, res) => {
      setCors(req, res);
      const locale = readLocale(req);

      if (req.method === 'OPTIONS') {
        return res.status(204).send('');
      }

      if (method && req.method !== method) {
        return sendError(
          res,
          405,
          'method-not-allowed',
          localizedText(locale, `${method} metodunu kullanın.`, `Use the ${method} method.`)
        );
      }

      try {
        await handler(req, res);
      } catch (error) {
        logger.error(`${name} failed: ${error.message}`);
        if (error.statusCode && error.message) {
          return sendError(
            res,
            error.statusCode,
            error.code || 'request-error',
            error.message
          );
        }
        return sendError(
          res,
          error.response?.status || error.statusCode || 500,
          'internal-error',
          localizedText(
            locale,
            'Beklenmeyen bir sunucu hatası oluştu.',
            'An unexpected server error occurred.'
          )
        );
      }
    }
  );
}

function createHttpError(statusCode, message) {
  const error = new Error(message);
  error.statusCode = statusCode;
  return error;
}

function emptyEstimateResponse(message) {
  return {
    item: null,
    message,
  };
}

function extractFatSecretError(data) {
  if (!data || typeof data !== 'object' || !data.error || typeof data.error !== 'object') {
    return null;
  }

  return {
    code: Number(data.error.code || 0),
    message: data.error.message || 'FatSecret search failed.',
  };
}

async function getFatSecretToken() {
  const now = Date.now();
  if (cachedFatSecretToken && now < fatSecretTokenExpiryMs - 60_000) {
    return cachedFatSecretToken;
  }

  const clientId = secretValue(FATSECRET_CLIENT_ID);
  const clientSecret = secretValue(FATSECRET_CLIENT_SECRET);

  if (!clientId || !clientSecret) {
    throw new Error('FatSecret secrets are missing.');
  }

  const encoded = Buffer.from(`${clientId}:${clientSecret}`).toString('base64');
  const response = await axios.post(
    'https://oauth.fatsecret.com/connect/token',
    'grant_type=client_credentials&scope=basic',
    {
      headers: {
        Authorization: `Basic ${encoded}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      timeout: 15000,
    }
  );

  cachedFatSecretToken = response.data.access_token;
  const expiresIn = Number(response.data.expires_in ?? 3600);
  fatSecretTokenExpiryMs = now + expiresIn * 1000;
  return cachedFatSecretToken;
}

async function callGroq({
  messages,
  modelKind = 'coach',
  model,
  temperature = 0.4,
  responseFormat,
}) {
  const apiKey = secretValue(GROQ_API_KEY);
  if (!apiKey || apiKey.startsWith('DISABLED')) {
    throw createHttpError(503, 'AI servisi henuz yapilandirilmadi.');
  }

  return callGroqChat({
    apiKey,
    messages,
    model,
    modelKind,
    temperature,
    responseFormat,
  });
}

function parseJsonContent(rawContent) {
  const trimmed = rawContent.trim();
  const normalized = trimmed
    .replace(/^```json\s*/i, '')
    .replace(/^```/, '')
    .replace(/```$/, '')
    .trim();

  return JSON.parse(normalized);
}

function firstNumberMatch(text, patterns) {
  for (const pattern of patterns) {
    const match = text.match(pattern);
    if (match) {
      return Number(match[1]);
    }
  }

  return null;
}

function extractEstimateFromText(rawContent, fallbackName) {
  const normalized = rawContent
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '');

  const calories = firstNumberMatch(normalized, [
    /(?:calories|kcal|kalori)[^0-9]*([0-9]+(?:\.[0-9]+)?)/i,
    /([0-9]+(?:\.[0-9]+)?)\s*(?:kcal|kalori|calories)/i,
  ]);
  const protein = firstNumberMatch(normalized, [
    /(?:protein)[^0-9]*([0-9]+(?:\.[0-9]+)?)/i,
  ]);
  const carbs = firstNumberMatch(normalized, [
    /(?:carbs?|karbonhidrat)[^0-9]*([0-9]+(?:\.[0-9]+)?)/i,
  ]);
  const fat = firstNumberMatch(normalized, [/(?:fat|yag)[^0-9]*([0-9]+(?:\.[0-9]+)?)/i]);

  if (calories == null && protein == null && carbs == null && fat == null) {
    return null;
  }

  return {
    name: fallbackName,
    calories: Math.round(calories ?? 0),
    protein: protein ?? 0,
    carbs: carbs ?? 0,
    fat: fat ?? 0,
    confidence: 0.35,
  };
}

async function readNutritionContext(uid, dateKey) {
  const summaryRef = admin.firestore().collection('users').doc(uid).collection('nutrition').doc(dateKey);

  const [summarySnapshot, mealsSnapshot] = await Promise.all([
    summaryRef.get(),
    summaryRef.collection('meals').orderBy('createdAt', 'desc').limit(10).get(),
  ]);

  return {
    summary: summarySnapshot.data() || {},
    meals: mealsSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() })),
  };
}

async function readDailyInsight(uid, dateKey) {
  const snapshot = await admin
    .firestore()
    .collection('users')
    .doc(uid)
    .collection('dailyInsights')
    .doc(dateKey)
    .get();

  return snapshot.data() || null;
}

function fallbackDailyNarrative(insight, locale) {
  const positive = normalizeQuery(insight?.positiveSignal);
  const risk = normalizeQuery(insight?.riskSignal);
  const action = normalizeQuery(insight?.tomorrowAction);

  if (locale === 'en') {
    return `Good: ${positive}. Risk: ${risk}. Tomorrow: ${action}.`;
  }

  return `İyi giden: ${positive}. Risk: ${risk}. Yarın: ${action}.`;
}

function buddyPairId(firstUid, secondUid) {
  return firstUid < secondUid
    ? `${firstUid}__${secondUid}`
    : `${secondUid}__${firstUid}`;
}

async function ensureAcceptedBuddyPair(senderUid, buddyUid) {
  const requestId = buddyPairId(senderUid, buddyUid);
  const snapshot = await admin.firestore().collection('buddyRequests').doc(requestId).get();
  const data = snapshot.data();
  if (!snapshot.exists || !data || data.status !== 'accepted') {
    throw createHttpError(403, 'Only accepted buddies can be nudged.');
  }
  return data;
}

async function ensureBuddyNudgeCooldown(senderUid, buddyUid) {
  const key = `${senderUid}__${buddyUid}`;
  const nudgeRef = admin.firestore().collection('buddyNudges').doc(key);
  const snapshot = await nudgeRef.get();
  const data = snapshot.data() || {};
  const lastSentAt = data.lastSentAt?.toDate?.();
  const now = Date.now();
  if (lastSentAt instanceof Date && now - lastSentAt.getTime() < 90 * 60 * 1000) {
    throw createHttpError(429, 'Buddy nudges are cooling down.');
  }
  return nudgeRef;
}

function buddyNudgeCopy(locale, senderName) {
  const firstName = normalizeQuery(senderName).split(' ')[0] || 'Buddy';
  return locale === 'en'
    ? {
        title: `${firstName} nudged you`,
        body: 'Drink a glass of water and keep your daily rhythm moving.',
      }
    : {
        title: `${firstName} seni dürttü`,
        body: 'Bir bardak su iç ve günlük ritmini devam ettir.',
      };
}

async function collectBuddyPushTargets(uid) {
  const snapshot = await admin
    .firestore()
    .collection('users')
    .doc(uid)
    .collection('pushTokens')
    .get();

  return snapshot.docs
    .map((doc) => ({ id: doc.id, ref: doc.ref, ...doc.data() }))
    .filter(
      (item) =>
        item.provider === 'fcm' &&
        typeof item.token === 'string' &&
        item.token.trim().length > 0 &&
        item.notificationsEnabled !== false
    );
}

async function cleanupInvalidPushTokens(targets, responses) {
  const invalidCodes = new Set([
    'messaging/registration-token-not-registered',
    'messaging/invalid-registration-token',
  ]);
  const invalidTargets = [];

  responses.forEach((response, index) => {
    const code = response.error?.code;
    if (code && invalidCodes.has(code)) {
      invalidTargets.push(targets[index]);
    }
  });

  await Promise.all(invalidTargets.map((target) => target.ref.delete().catch(() => null)));
}

exports.fatsecretSearch = createHttpFunction({
  name: 'fatsecretSearch',
  method: 'GET',
  secrets: [FATSECRET_CLIENT_ID, FATSECRET_CLIENT_SECRET],
  handler: async (req, res) => {
    const decodedToken = await authenticateRequest(req, res);
    if (!decodedToken) return;

    const locale = readLocale(req);
    const query = normalizeQuery(req.query.q || req.body?.q);
    const queryError = validateShortText(
      query,
      localizedText(locale, 'Sorgu', 'Query'),
      locale
    );
    if (queryError) {
      return sendError(res, 400, 'invalid-query', queryError);
    }

    logger.info('fatsecretSearch', {
      uid: decodedToken.uid,
      queryLength: query.length,
    });

    try {
      const token = await getFatSecretToken();
      const response = await axios.get('https://platform.fatsecret.com/rest/server.api', {
        params: {
          method: 'foods.search',
          search_expression: query,
          format: 'json',
        },
        headers: { Authorization: `Bearer ${token}` },
        timeout: 15000,
      });
      const fatSecretError = extractFatSecretError(response.data);
      if (fatSecretError != null) {
        if (fatSecretError.code === 21) {
          logger.warn(
            `fatsecretSearch upstream unavailable for current egress IP: ${fatSecretError.message}`
          );
          return res.json({
            foods: { food: [] },
            fallbackReason: 'fatsecret-ip-restriction',
          });
        }

        logger.error(
          `fatsecretSearch upstream failed: code=${fatSecretError.code} message=${fatSecretError.message}`
        );
        return sendError(
          res,
          502,
          'fatsecret-upstream-error',
          localizedText(
            locale,
            'FatSecret şu anda kullanılamıyor.',
            'FatSecret is unavailable right now.'
          )
        );
      }

      return res.json(response.data);
    } catch (error) {
      logger.error(
        `fatsecretSearch upstream failed: ${error.response?.status || error.statusCode || 500} ${error.message}`
      );
      return sendError(
        res,
        error.response?.status || 500,
        'fatsecret-error',
        localizedText(
          locale,
          'FatSecret araması başarısız oldu.',
          'FatSecret search failed.'
        )
      );
    }
  },
});

exports.foodEstimate = createHttpFunction({
  name: 'foodEstimate',
  method: 'POST',
  secrets: [GROQ_API_KEY],
  handler: async (req, res) => {
    const decodedToken = await authenticateRequest(req, res);
    if (!decodedToken) return;

    const locale = readLocale(req);
    const query = normalizeQuery(req.body?.query);
    const queryError = validateShortText(
      query,
      localizedText(locale, 'Yemek sorgusu', 'Food query'),
      locale
    );
    if (queryError) {
      return sendError(res, 400, 'invalid-query', queryError);
    }

    logger.info('foodEstimate', {
      uid: decodedToken.uid,
      queryLength: query.length,
    });

    try {
      const content = await callGroq({
        modelKind: 'estimate',
        temperature: 0.2,
        responseFormat: {
          type: 'json_object',
        },
        messages: [
          {
            role: 'system',
            content:
              'Estimate calories and macros for foods. Return JSON only with keys name, calories, protein, carbs, fat, confidence.',
          },
          { role: 'user', content: query },
        ],
      });

      let parsed;
      try {
        parsed = parseJsonContent(content);
      } catch (error) {
        parsed = extractEstimateFromText(content, query);
        if (parsed == null) {
          logger.error(`foodEstimate parse failed: ${error.message}`);
          return res.json(
            emptyEstimateResponse(
              localizedText(
                locale,
                'AI yanıtı işlenemedi. Manuel giriş yapabilirsiniz.',
                'The AI response could not be processed. You can use manual entry.'
              )
            )
          );
        }
      }

      return res.json({
        item: {
          name: parsed.name || query,
          calories: Number(parsed.calories || 0),
          protein: Number(parsed.protein || 0),
          carbs: Number(parsed.carbs || 0),
          fat: Number(parsed.fat || 0),
          source: 'ai_estimate',
          isEstimated: true,
          confidence: Number(parsed.confidence || 0.4),
        },
      });
    } catch (error) {
      logger.error(
        `foodEstimate upstream failed: ${error.response?.status || error.statusCode || 500} ${error.message}`
      );
      return res.json(
        emptyEstimateResponse(
          localizedText(
            locale,
            'AI tahmini şu anda kullanılamıyor. Manuel giriş yapabilirsiniz.',
            'The AI estimate is unavailable right now. You can use manual entry.'
          )
        )
      );
    }
  },
});

exports.dailyNarrative = createHttpFunction({
  name: 'dailyNarrative',
  method: 'POST',
  secrets: [GROQ_API_KEY],
  handler: async (req, res) => {
    const decodedToken = await authenticateRequest(req, res);
    if (!decodedToken) return;

    const locale = normalizeQuery(req.body?.locale).toLowerCase() === 'en' ? 'en' : 'tr';
    const insight = req.body?.insight || {};
    const score = Number(insight.consistencyScore ?? 0);
    const positiveSignal = normalizeQuery(insight.positiveSignal);
    const riskSignal = normalizeQuery(insight.riskSignal);
    const tomorrowAction = normalizeQuery(insight.tomorrowAction);

    if (!positiveSignal || !riskSignal || !tomorrowAction) {
      return sendError(
        res,
        400,
        'invalid-insight',
        'Insight signals are required.'
      );
    }

    try {
      const systemInstruction = locale === 'en'
        ? 'You turn deterministic nutrition insights into a concise daily narrative. Do not change the score, recovery decision, or next action.'
        : 'Deterministik beslenme içgörülerini kısa bir günlük anlatıma çevirirsin. Skoru, toparlanma kararını veya sonraki aksiyonu değiştirme.';
      const userInstruction = locale === 'en'
        ? 'Write 2 short sentences. Mention what went well, the risk, and the one action for tomorrow. No markdown.'
        : '2 kısa cümle yaz. İyi gideni, riski ve yarın için tek aksiyonu belirt. Markdown kullanma.';

      const narrative = await callGroq({
        modelKind: 'coach',
        temperature: 0.35,
        messages: [
          { role: 'system', content: systemInstruction },
          {
            role: 'user',
            content: [
              userInstruction,
              `Score: ${score}`,
              `Recovery mode: ${Boolean(insight.recoveryMode)}`,
              `Positive signal: ${positiveSignal}`,
              `Risk signal: ${riskSignal}`,
              `Tomorrow action: ${tomorrowAction}`,
            ].join('\n'),
          },
        ],
      });

      return res.json({ narrative: narrative.trim() });
    } catch (error) {
      logger.warn(`dailyNarrative fallback used: ${error.message}`);
      return res.json({
        narrative: fallbackDailyNarrative(insight, locale),
        fallback: true,
      });
    }
  },
});

exports.buddyNudge = createHttpFunction({
  name: 'buddyNudge',
  method: 'POST',
  handler: async (req, res) => {
    const decodedToken = await authenticateRequest(req, res);
    if (!decodedToken) return;

    const locale = readLocale(req);
    const buddyUid = normalizeQuery(req.body?.buddyUid);
    const buddyUidError = validateShortText(
      buddyUid,
      localizedText(locale, 'Buddy kullanıcısı', 'Buddy user'),
      locale
    );
    if (buddyUidError) {
      return sendError(res, 400, 'invalid-buddy', buddyUidError);
    }
    if (buddyUid === decodedToken.uid) {
      return sendError(
        res,
        400,
        'invalid-buddy',
        localizedText(locale, 'Kendine dürtme gönderemezsin.', 'You cannot send a nudge to yourself.')
      );
    }

    await ensureAcceptedBuddyPair(decodedToken.uid, buddyUid);
    const cooldownRef = await ensureBuddyNudgeCooldown(decodedToken.uid, buddyUid);

    const [senderSnapshot, targetTokens] = await Promise.all([
      admin.firestore().collection('users').doc(decodedToken.uid).get(),
      collectBuddyPushTargets(buddyUid),
    ]);

    if (targetTokens.length === 0) {
      return sendError(
        res,
        412,
        'buddy-notification-unavailable',
        localizedText(
          locale,
          'Buddy cihazında bildirimler henüz hazır değil.',
          'Buddy notifications are not ready on the other device yet.'
        )
      );
    }

    const senderName =
      normalizeQuery(senderSnapshot.data()?.name) ||
      normalizeQuery(decodedToken.name) ||
      normalizeQuery(decodedToken.email?.split('@')[0]) ||
      'Buddy';

    const messages = targetTokens.map((target) => {
      const tokenLocale = resolveLocale(target.localeCode);
      const copy = buddyNudgeCopy(tokenLocale, senderName);
      return {
        token: target.token.trim(),
        notification: {
          title: copy.title,
          body: copy.body,
        },
        data: {
          type: 'buddy_nudge',
          route: 'buddy',
          entityId: decodedToken.uid,
          title: copy.title,
          body: copy.body,
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'nudge_remote',
          },
        },
        apns: {
          headers: {
            'apns-priority': '10',
          },
          payload: {
            aps: {
              sound: 'default',
            },
          },
        },
      };
    });

    const batchResponse = await admin.messaging().sendEach(messages);
    await cleanupInvalidPushTokens(targetTokens, batchResponse.responses);
    const successCount = batchResponse.responses.filter((item) => item.success).length;
    if (successCount <= 0) {
      return sendError(
        res,
        503,
        'buddy-nudge-undelivered',
        localizedText(
          locale,
          'Buddy dürtmesi şu anda iletilemedi.',
          'The buddy nudge could not be delivered right now.'
        )
      );
    }

    await cooldownRef.set(
      {
        senderUid: decodedToken.uid,
        buddyUid,
        lastSentAt: admin.firestore.FieldValue.serverTimestamp(),
        sentCount: admin.firestore.FieldValue.increment(successCount),
      },
      { merge: true }
    );

    return res.json({
      delivered: true,
      sentCount: successCount,
      message: localizedText(
        locale,
        'Buddy dürtmesi gönderildi.',
        'Buddy nudge sent.'
      ),
    });
  },
});

exports.coachChat = createHttpFunction({
  name: 'coachChat',
  method: 'POST',
  secrets: [GROQ_API_KEY],
  handler: async (req, res) => {
    const decodedToken = await authenticateRequest(req, res);
    if (!decodedToken) return;

    const content = normalizeQuery(req.body?.content);
    const mode = normalizeQuery(req.body?.mode) || 'balanced coach';
    const locale = resolveLocale(req.body?.locale);
    const dateKey = /^\d{4}-\d{2}-\d{2}$/.test(req.body?.dateKey || '')
      ? req.body.dateKey
      : new Date().toISOString().split('T')[0];

    const contentError = validateShortText(
      content,
      localizedText(locale, 'Mesaj', 'Message'),
      locale
    );
    if (contentError) {
      return sendError(res, 400, 'invalid-message', contentError);
    }

      logger.info('coachChat', {
        uid: decodedToken.uid,
        mode,
        locale,
        messageLength: content.length,
      });

    try {
      const userSnapshot = await admin.firestore().collection('users').doc(decodedToken.uid).get();
      const [nutritionContext, dailyInsight] = await Promise.all([
        readNutritionContext(decodedToken.uid, dateKey),
        readDailyInsight(decodedToken.uid, dateKey),
      ]);
      const profile = userSnapshot.data() || {};

      const systemInstruction = locale === 'en'
        ? 'You are a data-driven fitness and nutrition coach. Stay consistent with the provided daily insight.'
        : 'Sen veriye dayalı bir fitness ve beslenme koçusun. Verilen günlük analizle çelişme.';
      const languageInstruction = locale === 'en'
        ? 'Respond in English with clear, brief, and actionable advice.'
        : 'Türkçe, net, kısa ve uygulanabilir tavsiyeler ver.';

      const prompt = [
        locale === 'en' ? `Mode: ${mode}` : `Mod: ${mode}`,
        locale === 'en'
          ? `User profile: ${JSON.stringify(profile)}`
          : `Kullanıcı profili: ${JSON.stringify(profile)}`,
        locale === 'en'
          ? `Daily summary: ${JSON.stringify(nutritionContext.summary)}`
          : `Günlük özet: ${JSON.stringify(nutritionContext.summary)}`,
        locale === 'en'
          ? `Recent meals: ${JSON.stringify(nutritionContext.meals)}`
          : `Son yemekler: ${JSON.stringify(nutritionContext.meals)}`,
        locale === 'en'
          ? `Daily insight: ${JSON.stringify(dailyInsight || {})}`
          : `Günlük analiz: ${JSON.stringify(dailyInsight || {})}`,
        locale === 'en'
          ? `User message: ${content}`
          : `Kullanıcı mesajı: ${content}`,
        languageInstruction,
      ].join('\n');

      const reply = await callGroq({
        modelKind: 'coach',
          messages: [
            {
              role: 'system',
              content: systemInstruction,
            },
          { role: 'user', content: prompt },
        ],
      });

      return res.json({ reply: reply.trim() });
    } catch (error) {
      logger.error(
        `coachChat upstream failed: ${error.response?.status || error.statusCode || 500} ${error.message}`
      );
        return sendError(
          res,
          error.statusCode || 500,
          error.statusCode == 503 ? 'ai-unavailable' : 'coach-error',
          error.statusCode == 503
          ? localizedText(
              locale,
              'AI koç şu anda aktif değil. Groq anahtarı tanımlanınca tekrar çalışacak.',
              'The AI coach is unavailable right now. It will start working again after the Groq key is configured.'
            )
          : localizedText(
              locale,
              'AI koç şu anda yanıt veremiyor.',
              'The AI coach cannot respond right now.'
            )
        );
    }
  },
});
