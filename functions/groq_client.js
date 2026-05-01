const axios = require('axios');

const DEFAULT_MODELS = {
  coach: 'llama-3.3-70b-versatile',
  estimate: 'openai/gpt-oss-20b',
  training: 'llama-3.3-70b-versatile',
  performance: 'llama-3.3-70b-versatile',
};

function resolveGroqModel(kind) {
  const envKey = `${kind.toUpperCase()}_MODEL`;
  const override = (process.env[envKey] || '').trim();
  if (override) {
    return override;
  }

  return DEFAULT_MODELS[kind] || DEFAULT_MODELS.coach;
}

async function callGroqChat({
  apiKey,
  messages,
  model,
  modelKind = 'coach',
  temperature = 0.4,
  responseFormat,
  timeoutMs = 15000,
}) {
  const resolvedKey = (apiKey || '').trim();
  if (!resolvedKey) {
    throw new Error('Missing Groq API key.');
  }

  const payload = {
    model: model || resolveGroqModel(modelKind),
    temperature,
    messages,
  };

  if (responseFormat) {
    payload.response_format = responseFormat;
  }

  const response = await axios.post(
    'https://api.groq.com/openai/v1/chat/completions',
    payload,
    {
      headers: {
        Authorization: `Bearer ${resolvedKey}`,
        'Content-Type': 'application/json',
      },
      timeout: timeoutMs,
    }
  );

  return response.data.choices?.[0]?.message?.content || '';
}

module.exports = {
  callGroqChat,
  resolveGroqModel,
};
